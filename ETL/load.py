"""
load.py — Carga idempotente de GeoDataFrames no PostGIS.

Funções públicas
----------------
get_engine(db_url)                                           → sqlalchemy.Engine
ensure_schema(engine, schema)                               → None
upsert_layer(gdf, layer_name, key_col, engine, pg_schema)   → int

Notas de implementação
----------------------
upsert_layer
    Estratégia de upsert:
    1. A estrutura da tabela destino (colunas, tipos, índices) é definida e
       garantida por `schema.py` (Schema_Manager), não inferida a partir do
       GeoDataFrame de origem.
    2. Como o to_postgis do geopandas não suporta ON CONFLICT nativamente,
       o upsert é implementado via INSERT ... ON CONFLICT DO UPDATE usando
       SQLAlchemy Core.

    Fluxo detalhado:
    a. Obtém o `AssetTableSpec` da layer via `schema.get_spec` e garante a
       estrutura da tabela destino via `schema.ensure_asset_table`.
    b. Projeta o GeoDataFrame recebido para exatamente `schema.FIXED_COLUMNS`,
       descartando quaisquer colunas extras vindas de `transform.py`.
    c. Para cada batch do GeoDataFrame, executa:
         INSERT INTO destino (...) VALUES (...)
         ON CONFLICT (asset_key) DO UPDATE SET <todas as colunas não-chave>
    d. Retorna o número de linhas processadas.

Alternativa mais simples (usada aqui para evitar dependência de psycopg2 extras):
    - Usa INSERT ... ON CONFLICT (asset_key) DO UPDATE via text() do SQLAlchemy
    - Isso é compatível com PostgreSQL >= 9.5
"""
from __future__ import annotations

import logging
import re

import geopandas as gpd
import pandas as pd
import sqlalchemy as sa
from sqlalchemy import text

import schema

logger = logging.getLogger(__name__)

# Tamanho dos lotes de upsert (linhas por INSERT)
BATCH_SIZE = 5_000


# ---------------------------------------------------------------------------
# Engine
# ---------------------------------------------------------------------------

def get_engine(db_url: str) -> sa.Engine:
    """Cria e retorna uma engine SQLAlchemy para o banco de dados.

    Parameters
    ----------
    db_url:
        Connection string PostgreSQL, ex.:
        "postgresql://postgres:postgres@localhost:5432/bdgd"

    Returns
    -------
    sqlalchemy.Engine
    """
    try:
        engine = sa.create_engine(
            db_url,
            pool_pre_ping=True,
            connect_args={"client_encoding": "utf8"},
        )
        # Valida a conexão imediatamente
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        logger.info("Conexão ao banco estabelecida: %s", _mask_password(db_url))
        return engine
    except Exception as exc:
        # Trata erros de codificação quando o Postgres no Windows responde mensagens de erro em CP1252 (ex: "autenticação falhou")
        if isinstance(exc, UnicodeDecodeError) or "codec can't decode" in str(exc):
            raw_bytes = getattr(exc, "object", None)
            if isinstance(raw_bytes, bytes):
                decoded_msg = raw_bytes.decode("latin1", errors="replace").strip()
                raise RuntimeError(f"Erro de conexão com PostgreSQL: {decoded_msg}") from exc
        raise



def _mask_password(url: str) -> str:
    """Remove a senha da connection string para logging seguro."""
    return re.sub(r"(:)[^:@]+(@)", r"\1***\2", url)


# ---------------------------------------------------------------------------
# Schema
# ---------------------------------------------------------------------------

def ensure_schema(engine: sa.Engine, schema: str) -> None:
    """Cria o schema no banco se não existir."""
    with engine.begin() as conn:
        conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {schema}"))
    logger.info("Schema '%s' garantido.", schema)


# ---------------------------------------------------------------------------
# Upsert
# ---------------------------------------------------------------------------

def upsert_layer(
    gdf: gpd.GeoDataFrame,
    layer_name: str,
    key_col: str,
    engine: sa.Engine,
    pg_schema: str,
) -> int:
    """Faz upsert idempotente do GeoDataFrame na tabela PostGIS.

    Para cada feição:
    - Se asset_key ainda não existir → insere.
    - Se asset_key já existir        → atualiza todas as colunas não-chave.

    Parameters
    ----------
    gdf:
        GeoDataFrame transformado (já com as colunas normalizadas, incluindo
        asset_key). Colunas fora de `schema.FIXED_COLUMNS` são descartadas.
    layer_name:
        Nome da Layer (ex. "POSTE") — usado para obter o `AssetTableSpec` via
        `schema.get_spec` e derivar o nome real da tabela destino.
    key_col:
        Coluna chave original (ex. "COD_ID") — usada apenas para logging.
    engine:
        Engine SQLAlchemy conectada ao banco.
    pg_schema:
        Nome do schema no banco (ex. "bdgd").

    Returns
    -------
    int
        Número de feições processadas (inseridas + atualizadas).
    """
    if gdf.empty:
        logger.warning("GeoDataFrame vazio para '%s' — nada a carregar.", layer_name)
        return 0

    # 1. Obtém a spec da layer e garante que a tabela existe com a estrutura correta
    spec = schema.get_spec(layer_name)
    schema.ensure_asset_table(engine, layer_name, pg_schema)
    table_name = spec.table_name

    # 2. Projeta o GeoDataFrame para exatamente as colunas normalizadas fixas,
    #    descartando quaisquer colunas extras vindas de transform.py
    gdf = pd.DataFrame(gdf[list(schema.FIXED_COLUMNS)].copy())

    # 3. Converte geometria para WKT + SRID para compatibilidade com psycopg2
    srid = 4326  # TARGET_CRS já foi aplicado pelo transform.py
    gdf["geometry"] = gdf["geometry"].apply(
        lambda geom: f"SRID={srid};{geom.wkt}" if geom is not None else None
    )

    # 4. Upsert em batches com executemany (muito mais eficiente que row-by-row)
    total_processed = 0

    # Monta a query uma única vez (as colunas não mudam entre linhas)
    sample_row = gdf.iloc[0].to_dict()
    col_names = list(sample_row.keys())
    col_list = ", ".join(col_names)
    col_list_cast = ", ".join(
        "CAST(:geometry AS geometry)" if c == "geometry" else f":{c}"
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
