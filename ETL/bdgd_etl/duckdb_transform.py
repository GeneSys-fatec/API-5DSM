"""
bdgd_etl.duckdb_transform — Vectorized spatial transformations using DuckDB + Spatial extension.
Executes CRS reprojection, geometry validation, filtering, key resolution, and
staging serialization directly on GeoParquet files without pure pandas.
"""
from __future__ import annotations

import logging
from pathlib import Path
from typing import Any

import duckdb

logger = logging.getLogger(__name__)


def inspect_parquet_schema(parquet_path: Path) -> dict[str, str]:
    """Returns mapping of column_name -> column_type from Parquet metadata."""
    norm_path = str(parquet_path).replace("\\", "/")
    con = duckdb.connect()
    try:
        con.execute("INSTALL spatial; LOAD spatial;")
        rows = con.execute(f"DESCRIBE SELECT * FROM read_parquet('{norm_path}')").fetchall()
        return {r[0]: r[1] for r in rows}
    finally:
        con.close()


def resolve_geometry_column(columns: dict[str, str]) -> str:
    """Detects the geometry column name in the Parquet file."""
    # Check for GEOMETRY types first
    for col_name, col_type in columns.items():
        if "GEOMETRY" in col_type.upper():
            return col_name

    # Check standard geometry column names
    candidates = ["Shape", "geom", "geometry", "SHAPE", "GEOMETRY", "wkb_geometry"]
    for c in candidates:
        if c in columns:
            return c

    raise ValueError(
        f"Nenhuma coluna de geometria detectada. Colunas disponíveis: {list(columns.keys())}"
    )


def resolve_key_column(columns: dict[str, str], preferred_key: str = "COD_ID") -> str:
    """Finds the unique key column (COD_ID, OBJECTID, FID, etc.)."""
    # 1. Preferred key
    for col_name in columns:
        if col_name.upper() == preferred_key.upper():
            return col_name

    # 2. Fallbacks
    fallbacks = ["OBJECTID", "FID", "ID", "GLOBALID", "CODIGO"]
    for fb in fallbacks:
        for col_name in columns:
            if col_name.upper() == fb:
                logger.info("Usando coluna fallback '%s' como identificador da layer.", col_name)
                return col_name

    # 3. Default to first non-geom column
    for col_name, col_type in columns.items():
        if "GEOMETRY" not in col_type.upper():
            logger.warning("Usando primeira coluna '%s' como identificador de ativo.", col_name)
            return col_name

    raise KeyError(f"Nenhum campo chave identificador encontrado em {list(columns.keys())}")


def transform_geoparquet_to_staging(
    parquet_path: Path,
    staging_tsv_path: Path,
    layer_name: str,
    target_layer_name: str,
    distribuidora: str,
    regiao: str,
    source_srid: int = 4674,
    target_srid: int = 4326,
    filter_spec: dict[str, str] | None = None,
    import_id: str | None = None,
) -> int:
    """Executes high-performance DuckDB spatial transformations on intermediate GeoParquet.

    Operations:
    1. Filter out NULL and empty geometries
    2. Apply layer fallback filters if applicable (e.g. TIP_PN = 'POS')
    3. Reproject geometries to target_srid (e.g. EPSG:4674 -> EPSG:4326)
    4. Generate unique asset_key: '{target_layer}::{distribuidora}::{key_value}'
    5. Export directly to TSV format for bulk loading (WKT formatted geometry)

    Returns
    -------
    int
        Number of valid features written to the staging file.
    """
    columns = inspect_parquet_schema(parquet_path)
    geom_col = resolve_geometry_column(columns)
    key_col = resolve_key_column(columns)

    norm_parquet = str(parquet_path).replace("\\", "/")
    norm_staging = str(staging_tsv_path).replace("\\", "/")

    con = duckdb.connect()
    try:
        con.execute("INSTALL spatial; LOAD spatial;")

        # Early exit if the Parquet file has 0 rows
        count_res = con.execute(f"SELECT count(*) FROM read_parquet('{norm_parquet}')").fetchone()
        if not count_res or count_res[0] == 0:
            logger.info("[%s] Layer vazia (0 feições no Parquet). Criando staging vazio.", layer_name)
            with open(staging_tsv_path, "w", encoding="utf-8") as f:
                pass
            return 0

        geom_type = columns.get(geom_col, "").upper()
        if "GEOMETRY" in geom_type:
            geom_ref = f'"{geom_col}"'
        else:
            geom_ref = f'ST_GeomFromWKB("{geom_col}")'

        # Build WHERE clause
        where_clauses = [
            f'"{geom_col}" IS NOT NULL',
            f'NOT ST_IsEmpty({geom_ref})',
        ]

        if filter_spec:
            f_col = filter_spec["filter_col"]
            f_val = filter_spec["filter_value"]
            if f_col in columns:
                where_clauses.append(f'CAST("{f_col}" AS VARCHAR) = \'{f_val}\'')
                logger.info(
                    "[%s] Aplicando filtro de fallback no DuckDB: %s = '%s'",
                    layer_name,
                    f_col,
                    f_val,
                )
            else:
                logger.warning(
                    "[%s] Coluna de filtro de fallback '%s' não encontrada na layer.",
                    layer_name,
                    f_col,
                )

        where_expr = " AND ".join(where_clauses)

        # Reprojection expression:
        # If source SRID differs from target SRID, apply ST_Transform
        if source_srid == target_srid:
            geom_expr = f'ST_AsText({geom_ref})'
        else:
            geom_expr = (
                f'ST_AsText(ST_Transform({geom_ref}, '
                f"'EPSG:{source_srid}', 'EPSG:{target_srid}', always_xy := true))"
            )

        # Escape single quotes in metadata
        clean_target_layer = target_layer_name.replace("'", "''")
        clean_dist = distribuidora.replace("'", "''")
        clean_regiao = regiao.replace("'", "''")
        clean_import_id = (import_id or "").replace("'", "''")
        asset_prefix = f"{clean_target_layer}::{clean_dist}::{clean_import_id}"

        sql_query = f"""
            COPY (
                SELECT
                    '{clean_target_layer}' AS tipo_ativo,
                    '{clean_dist}' AS distribuidora,
                    '{clean_regiao}' AS regiao,
                    NULLIF('{clean_import_id}', '') AS importacao_id,
                    '{asset_prefix}' || '::' || CAST("{key_col}" AS VARCHAR) AS asset_key,
                    {geom_expr} AS geom_wkt
                FROM read_parquet('{norm_parquet}')
                WHERE {where_expr}
            ) TO '{norm_staging}' (FORMAT CSV, DELIMITER '\t', HEADER FALSE, QUOTE '"')
        """

        con.execute(sql_query)

        # Count features written to staging
        count_res = con.execute(
            f"SELECT count(*) FROM read_csv('{norm_staging}', delim='\t', header=false)"
        ).fetchone()
        valid_features = count_res[0] if count_res else 0

        logger.info(
            "[%s -> %s] Transformação espacial via DuckDB concluída: %d feições prontas para carga.",
            layer_name,
            target_layer_name,
            valid_features,
        )
        return valid_features
    finally:
        con.close()
