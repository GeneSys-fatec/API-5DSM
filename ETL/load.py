from __future__ import annotations

import logging
import re
from sqlalchemy import Table, MetaData
from sqlalchemy.dialects.postgresql import insert
import geopandas as gpd
import pandas as pd
import sqlalchemy as sa
from sqlalchemy import text

import schema

logger = logging.getLogger(__name__)

BATCH_SIZE = 5_000


def get_engine(db_url: str) -> sa.Engine:
    try:
        engine = sa.create_engine(
            db_url,
            pool_pre_ping=True,
            connect_args={"client_encoding": "utf8"}
        )
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        logger.info("Conexão ao banco estabelecida: %s", _mask_password(db_url))
        return engine
    except Exception as exc:
        if isinstance(exc, UnicodeDecodeError) or "codec can't decode" in str(exc):
            raw_bytes = getattr(exc, "object", None)
            if isinstance(raw_bytes, bytes):
                decoded_msg = raw_bytes.decode("latin1", errors="replace").strip()
                raise RuntimeError(f"Erro de conexão com PostgreSQL: {decoded_msg}") from exc
        raise



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

    gdf = pd.DataFrame(gdf[list(schema.FIXED_COLUMNS)].copy())

    srid = 4326
    gdf["geometry"] = gdf["geometry"].apply(
        lambda geom: f"SRID={srid};{geom.wkt}" if geom is not None else None
    )

    total_processed = 0

    # 1. Lê a definição da tabela diretamente da base de dados
    metadata = MetaData()
    table = Table(table_name, metadata, schema=pg_schema, autoload_with=engine)

    for start in range(0, len(gdf), BATCH_SIZE):
        batch = gdf.iloc[start : start + BATCH_SIZE]
        rows = batch.to_dict(orient="records")

        # 2. Constrói a instrução de INSERT
        stmt = insert(table).values(rows)
        
        # 3. Monta dinamicamente as colunas do DO UPDATE (excluindo a chave de conflito)
        update_set = {
            c.name: c for c in stmt.excluded 
            if c.name != "asset_key"
        }
        
        # 4. Anexa o comportamento ON CONFLICT (Upsert)
        upsert_stmt = stmt.on_conflict_do_update(
            index_elements=["asset_key"],
            set_=update_set
        )

        # 5. Executa na base de dados (O SQLAlchemy 2.0 empacota as 5000 linhas automaticamente aqui)
        with engine.begin() as conn:
            conn.execute(upsert_stmt)

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
