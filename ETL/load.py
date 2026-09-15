"""
load.py — Carga idempotente de GeoDataFrames no PostGIS.

Funções públicas
----------------
get_engine(db_url)                                           → sqlalchemy.Engine
ensure_schema(engine, schema)                               → None
upsert_layer(gdf, table_name, key_col, engine, schema)      → int

Notas de implementação
----------------------
upsert_layer
    Estratégia de upsert:
    1. Cria a tabela no PostGIS via GeoDataFrame.to_postgis() com
       if_exists="append" + tabela já criada.
       Porém, o to_postgis do geopandas não suporta ON CONFLICT nativamente,
       então o upsert é implementado via uma tabela temporária + MERGE/INSERT
       SELECT com ON CONFLICT DO UPDATE usando SQLAlchemy Core.

    Fluxo detalhado:
    a. Cria tabela destino (se não existir) usando to_postgis(..., if_exists="fail")
       dentro de um try/except — se já existir, ignora.
    b. Garante índice UNIQUE em asset_key e índice GiST em geometry.
    c. Para cada batch do GeoDataFrame, insere em tabela temporária e executa:
         INSERT INTO destino SELECT ... FROM tmp
         ON CONFLICT (asset_key) DO UPDATE SET <todas as colunas não-chave>
    d. Retorna o número de linhas processadas.

Alternativa mais simples (usada aqui para evitar dependência de psycopg2 extras):
    - Cria tabela destino se não existir (estrutura vinda do primeiro to_postgis)
    - Usa INSERT ... ON CONFLICT (asset_key) DO UPDATE via text() do SQLAlchemy
    - Isso é compatível com PostgreSQL >= 9.5
"""
from __future__ import annotations

import logging
import re

import geopandas as gpd
import sqlalchemy as sa
from sqlalchemy import text

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
    engine = sa.create_engine(db_url, pool_pre_ping=True)
    # Valida a conexão imediatamente
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
    logger.info("Conexão ao banco estabelecida: %s", _mask_password(db_url))
    return engine


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
# Criação de tabela e índices
# ---------------------------------------------------------------------------

def _ensure_table(
    gdf: gpd.GeoDataFrame,
    table_name: str,
    schema: str,
    engine: sa.Engine,
    srid: int = 4326,
) -> None:
    """Cria a tabela no PostGIS se não existir, usando o GDF como modelo."""
    inspector = sa.inspect(engine)
    if inspector.has_table(table_name, schema=schema):
        logger.debug("Tabela '%s.%s' já existe.", schema, table_name)
        return

    logger.info("Criando tabela '%s.%s' …", schema, table_name)
    # to_postgis cria a tabela com o schema correto; usamos if_exists="fail"
    # para garantir que não sobrescrevemos dados acidentalmente.
    # Passamos apenas as primeiras linhas para não carregar tudo duas vezes.
    sample = gdf.head(1).copy()
    sample.to_postgis(
        table_name,
        engine,
        schema=schema,
        if_exists="fail",
        index=False,
    )
    # Apaga as linhas de amostra — serão inseridas pelo upsert
    with engine.begin() as conn:
        conn.execute(text(f"DELETE FROM {schema}.{table_name}"))

    _ensure_indexes(engine, schema, table_name, srid)


def _ensure_indexes(
    engine: sa.Engine,
    schema: str,
    table_name: str,
    srid: int,
) -> None:
    """Garante índice UNIQUE em asset_key e índice GiST em geometry."""
    with engine.begin() as conn:
        # UNIQUE em asset_key — usamos CREATE UNIQUE INDEX (suportado pelo
        # PostgreSQL >= 8.x) em vez de ALTER TABLE ADD CONSTRAINT IF NOT EXISTS
        # (que não existe para constraints no Postgres).
        conn.execute(text(f"""
            CREATE UNIQUE INDEX IF NOT EXISTS uq_{table_name}_asset_key
            ON {schema}.{table_name} (asset_key)
        """))

        # Índice GiST para queries espaciais
        conn.execute(text(f"""
            CREATE INDEX IF NOT EXISTS idx_{table_name}_geometry
            ON {schema}.{table_name}
            USING GIST (geometry)
        """))
    logger.info(
        "Índices UNIQUE(asset_key) e GiST(geometry) garantidos em '%s.%s'.",
        schema, table_name,
    )


# ---------------------------------------------------------------------------
# Upsert
# ---------------------------------------------------------------------------

def upsert_layer(
    gdf: gpd.GeoDataFrame,
    table_name: str,
    key_col: str,
    engine: sa.Engine,
    schema: str,
) -> int:
    """Faz upsert idempotente do GeoDataFrame na tabela PostGIS.

    Para cada feição:
    - Se asset_key ainda não existir → insere.
    - Se asset_key já existir        → atualiza todas as colunas não-chave.

    Parameters
    ----------
    gdf:
        GeoDataFrame transformado (já com coluna asset_key).
    table_name:
        Nome da tabela destino (sem schema).
    key_col:
        Coluna chave original (ex. "COD_ID") — usada apenas para logging.
    engine:
        Engine SQLAlchemy conectada ao banco.
    schema:
        Nome do schema no banco (ex. "bdgd").

    Returns
    -------
    int
        Número de feições processadas (inseridas + atualizadas).
    """
    if gdf.empty:
        logger.warning("GeoDataFrame vazio para '%s' — nada a carregar.", table_name)
        return 0

    # 1. Garante que a tabela existe com a estrutura correta
    _ensure_table(gdf, table_name, schema, engine)

    # 2. Converte geometria para WKT + SRID para compatibilidade com psycopg2
    gdf = gdf.copy()
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
        f":{c}::geometry" if c == "geometry" else f":{c}"
        for c in col_names
    )
    update_set = ", ".join(
        f"{c} = EXCLUDED.{c}"
        for c in col_names
        if c != "asset_key"
    )
    sql = text(f"""
        INSERT INTO {schema}.{table_name} ({col_list})
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
        total_processed, schema, table_name,
    )
    return total_processed
