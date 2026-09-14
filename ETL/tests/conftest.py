from __future__ import annotations

import logging
import sys
from pathlib import Path

import pytest
import sqlalchemy as sa
from sqlalchemy import text

# Garante que os módulos do pipeline (config.py, load.py, ...), que vivem em
# ETL/ (diretório pai de ETL/tests/), sejam importáveis independentemente de
# onde o pytest é invocado.
_ETL_DIR = Path(__file__).resolve().parent.parent
if str(_ETL_DIR) not in sys.path:
    sys.path.insert(0, str(_ETL_DIR))

import config  # noqa: E402

logger = logging.getLogger(__name__)

# Schema isolado usado pelos testes de integração. Propositalmente distinto
# de config.SCHEMA ("bdgd") para nunca arriscar dados reais do pipeline.
TEST_SCHEMA = "bdgd_test"


@pytest.fixture(scope="session")
def engine() -> sa.Engine:
    """Engine SQLAlchemy conectada ao mesmo Postgres/PostGIS local usado
    pelo pipeline ETL (mesma `BDGD_DB_URL` de `config.DB_URL`).

    `load.get_engine` é importado dentro da fixture (não no topo do módulo)
    para que a coleta de testes (`pytest --collect-only`) não dependa de
    `geopandas`/GDAL estarem instalados no ambiente — só é necessário quando
    um teste de integração de fato usa esta fixture.

    Se não houver banco acessível no ambiente, os testes que dependem desta
    fixture (diretamente ou via `pg_schema`) são pulados (skip) em vez de
    falhar — nenhum banco é iniciado automaticamente.
    """
    try:
        import load  

        eng = load.get_engine(config.DB_URL)
    except Exception as exc: 
        pytest.skip(f"Banco de dados indisponível em BDGD_DB_URL ({exc}).")
        return  

    yield eng
    eng.dispose()


@pytest.fixture()
def pg_schema(engine: sa.Engine) -> str:
    with engine.begin() as conn:
        conn.execute(text(f"DROP SCHEMA IF EXISTS {TEST_SCHEMA} CASCADE"))
        conn.execute(text(f"CREATE SCHEMA {TEST_SCHEMA}"))
    logger.debug("Schema de teste '%s' criado.", TEST_SCHEMA)

    yield TEST_SCHEMA

    with engine.begin() as conn:
        conn.execute(text(f"DROP SCHEMA IF EXISTS {TEST_SCHEMA} CASCADE"))
    logger.debug("Schema de teste '%s' derrubado.", TEST_SCHEMA)
