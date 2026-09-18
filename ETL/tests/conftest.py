from __future__ import annotations

import logging
import sys
from pathlib import Path

import pytest
import sqlalchemy as sa
from sqlalchemy import text

_ETL_DIR = Path(__file__).resolve().parent.parent
if str(_ETL_DIR) not in sys.path:
    sys.path.insert(0, str(_ETL_DIR))

import config  # noqa: E402

logger = logging.getLogger(__name__)

TEST_SCHEMA = "bdgd_test"


@pytest.fixture(scope="session")
def engine() -> sa.Engine:
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
