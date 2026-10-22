"""
bdgd_etl.duckdb_spatial — Safe loading of the DuckDB ``spatial`` extension.
Concurrent workers running ``INSTALL spatial`` race on the shared extension directory
(``~/.duckdb``) and fail with "Could not move file" / "Failed to create directory".
The pipeline installs the extension once up front; workers only ``LOAD`` it, retrying
the install if the extension is still missing.
"""
from __future__ import annotations

import logging
import time

import duckdb

logger = logging.getLogger(__name__)

_INSTALL_ATTEMPTS = 5
_RETRY_BASE_DELAY_S = 0.5


def _install_with_retries(con) -> None:
    last_error: Exception | None = None
    for attempt in range(1, _INSTALL_ATTEMPTS + 1):
        try:
            con.execute("INSTALL spatial")
            return
        except duckdb.Error as exc:
            last_error = exc
            logger.warning(
                "Falha ao instalar extensão spatial (tentativa %d/%d): %s",
                attempt, _INSTALL_ATTEMPTS, exc,
            )
            if attempt < _INSTALL_ATTEMPTS:
                time.sleep(_RETRY_BASE_DELAY_S * attempt)
    assert last_error is not None
    raise last_error


def install_spatial_extension() -> None:
    """Installs the spatial extension once, from a single process."""
    con = duckdb.connect()
    try:
        _install_with_retries(con)
    finally:
        con.close()


def load_spatial(con) -> None:
    """Loads the spatial extension, installing it (with retries) only if missing."""
    try:
        con.execute("LOAD spatial")
    except duckdb.Error:
        _install_with_retries(con)
        con.execute("LOAD spatial")
