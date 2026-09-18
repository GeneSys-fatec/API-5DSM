from __future__ import annotations

import logging
import re

import geopandas as gpd
import sqlalchemy as sa
from sqlalchemy import text

import schema

logger = logging.getLogger(__name__)

BATCH_SIZE = 5_000


def get_engine(db_url: str) -> sa.Engine:
    engine = sa.create_engine(db_url, pool_pre_ping=True)
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
    logger.info("Conexão ao banco estabelecida: %s", _mask_password(db_url))
    return engine


def _mask_password(url: str) -> str:
    return re.sub(r"(:)[^:@]+(@)", r"\1***\2", url)


def ensure_schema(engine: sa.Engine, schema: str) -> None:
    with engine.begin() as conn:
        conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {schema}"))
    logger.info("Schema '%s' garantido.", schema)


def upsert_layer(
    gdf: gpd.GeoDataFrame,
    layer_name: str,
    key_col: str,
    engine: sa.Engine,
    pg_schema: str,
) -> int:
    if gdf.empty:
        logger.warning("GeoDataFrame vazio para '%s' — nada a carregar.", layer_name)
        return 0

    spec = schema.get_spec(layer_name)
    schema.ensure_asset_table(engine, layer_name, pg_schema)
    table_name = spec.table_name

    gdf = gdf[list(schema.FIXED_COLUMNS)].copy()

    srid = 4326
    gdf["geometry"] = gdf["geometry"].apply(
        lambda geom: f"SRID={srid};{geom.wkt}" if geom is not None else None
    )

    total_processed = 0

    sample_row = gdf.iloc[0].to_dict()
    col_names = list(sample_row.keys())
    col_list = ", ".join(col_names)
    col_list_cast = ", ".join(
        f"CAST(:{c} AS geometry)" if c == "geometry" else f":{c}"
        for c in col_names
    )
    update_set = ", ".join(
        f"{c} = EXCLUDED.{c}"
        for c in col_names
        if c != "asset_key"
    )
    sql = text(f"""
        INSERT INTO {pg_schema}.{table_name} ({col_list})
        VALUES ({col_list_cast})
        ON CONFLICT (asset_key)
        DO UPDATE SET {update_set}
    """)

    for start in range(0, len(gdf), BATCH_SIZE):
        batch = gdf.iloc[start : start + BATCH_SIZE]
        rows = batch.to_dict(orient="records")

        with engine.begin() as conn:
            conn.execute(sql, rows)

        total_processed += len(batch)
        logger.info(
            "Batch %d–%d de '%s' carregado.",
            start + 1, start + len(batch), table_name,
        )

    logger.info(
        "upsert_layer: %d feições processadas em '%s.%s'.",
        total_processed, pg_schema, table_name,
    )
    return total_processed
