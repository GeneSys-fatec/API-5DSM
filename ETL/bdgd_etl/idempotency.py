"""
bdgd_etl.idempotency — Hash-based idempotency manager.
Computes SHA-256 of the BDGD zip archive and tracks layer processing history in the database.
Skips layers that have already been processed without changes unless force=True.
"""
from __future__ import annotations

import hashlib
import json
import logging
from pathlib import Path
from typing import Optional

import psycopg2

logger = logging.getLogger(__name__)


def compute_file_sha256(file_path: str | Path, chunk_size: int = 1024 * 1024) -> str:
    """Computes SHA-256 hash of a file reading in 1MB chunks."""
    path_obj = Path(file_path).resolve()
    if not path_obj.exists():
        raise FileNotFoundError(f"Arquivo para cálculo de hash não encontrado: {file_path}")

    hasher = hashlib.sha256()
    with open(path_obj, "rb") as f:
        while chunk := f.read(chunk_size):
            hasher.update(chunk)

    digest = hasher.hexdigest()
    logger.debug("SHA-256 calculado para %s: %s", path_obj.name, digest)
    return digest


class IdempotencyManager:
    """Tracks and checks execution state in the database table and fallback cache."""

    def __init__(self, db_url: str, schema: str = "bdgd"):
        self.db_url = db_url
        self.schema = schema
        self._local_cache_file = Path(".etl_state.json")

    def _get_connection(self):
        return psycopg2.connect(self.db_url, connect_timeout=10, client_encoding="utf-8")

    def ensure_state_table(self) -> None:
        """Creates the _etl_state table in the database if it doesn't exist."""
        try:
            with self._get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(f"""
                        CREATE TABLE IF NOT EXISTS {self.schema}._etl_state (
                            file_hash VARCHAR(64) NOT NULL,
                            file_name TEXT NOT NULL,
                            layer_name VARCHAR(120) NOT NULL,
                            feature_count BIGINT DEFAULT 0,
                            processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                            elapsed_s DOUBLE PRECISION DEFAULT 0.0,
                            peak_memory_mb DOUBLE PRECISION DEFAULT 0.0,
                            status VARCHAR(20) NOT NULL,
                            error_message TEXT,
                            PRIMARY KEY (file_hash, layer_name)
                        );
                    """)
                conn.commit()
        except Exception as exc:
            logger.warning("Não foi possível conectar ao banco para tabela de estado: %s. Usando cache local.", exc)

    def is_layer_processed(self, file_hash: str, layer_name: str) -> bool:
        """Returns True if the layer was previously processed successfully for this file hash."""
        clean_layer = layer_name.strip()
        try:
            with self._get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(f"""
                        SELECT status FROM {self.schema}._etl_state
                        WHERE file_hash = %s AND UPPER(layer_name) = UPPER(%s);
                    """, (file_hash, clean_layer))
                    row = cur.fetchone()
                    if row and row[0] == "SUCCESS":
                        return True
            return False
        except Exception:
            # Fallback to local cache
            if self._local_cache_file.exists():
                try:
                    with open(self._local_cache_file, "r", encoding="utf-8") as f:
                        data = json.load(f)
                    return data.get(f"{file_hash}::{clean_layer.upper()}") == "SUCCESS"
                except Exception:
                    pass
            return False

    def record_result(
        self,
        file_hash: str,
        file_name: str,
        layer_name: str,
        feature_count: int,
        elapsed_s: float,
        peak_memory_mb: float,
        status: str,
        error_message: str | None = None,
    ) -> None:
        """Persists the processing result for idempotency tracking."""
        clean_layer = layer_name.strip()
        try:
            with self._get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(f"""
                        INSERT INTO {self.schema}._etl_state (
                            file_hash, file_name, layer_name, feature_count,
                            processed_at, elapsed_s, peak_memory_mb, status, error_message
                        ) VALUES (%s, %s, %s, %s, CURRENT_TIMESTAMP, %s, %s, %s, %s)
                        ON CONFLICT (file_hash, layer_name) DO UPDATE SET
                            feature_count = EXCLUDED.feature_count,
                            processed_at = CURRENT_TIMESTAMP,
                            elapsed_s = EXCLUDED.elapsed_s,
                            peak_memory_mb = EXCLUDED.peak_memory_mb,
                            status = EXCLUDED.status,
                            error_message = EXCLUDED.error_message;
                    """, (
                        file_hash, file_name, clean_layer, feature_count,
                        elapsed_s, peak_memory_mb, status, error_message
                    ))
                conn.commit()
        except Exception as exc:
            logger.warning("Falha ao salvar estado de idempotência no banco: %s. Salvando no cache local.", exc)
            try:
                data = {}
                if self._local_cache_file.exists():
                    with open(self._local_cache_file, "r", encoding="utf-8") as f:
                        data = json.load(f)
                data[f"{file_hash}::{clean_layer.upper()}"] = status
                with open(self._local_cache_file, "w", encoding="utf-8") as f:
                    json.dump(data, f, indent=2)
            except Exception:
                pass
