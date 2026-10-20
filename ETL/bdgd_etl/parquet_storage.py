"""
bdgd_etl.parquet_storage — Intermediate GeoParquet stage and lifecycle management.
Extracts layers from GDAL /vsizip/ directly into GeoParquet files, and ensures
automatic cleanup of temporary files upon successful load into the database.
"""
from __future__ import annotations

import logging
import os
import tempfile
from pathlib import Path
from typing import Optional

import duckdb

logger = logging.getLogger(__name__)


class ParquetStage:
    """Manages intermediate GeoParquet file extraction and automatic cleanup."""

    def __init__(self, temp_base_dir: str | Path | None = None, auto_cleanup: bool = True):
        self.base_dir = Path(temp_base_dir) if temp_base_dir else Path(tempfile.gettempdir())
        self.base_dir.mkdir(parents=True, exist_ok=True)
        self.auto_cleanup = auto_cleanup
        self._tracked_files: list[Path] = []

    def get_parquet_path(self, layer_name: str, run_id: str) -> Path:
        filename = f"bdgd_{run_id}_{layer_name}.parquet"
        path = self.base_dir / filename
        self._tracked_files.append(path)
        return path

    def get_staging_tsv_path(self, layer_name: str, run_id: str) -> Path:
        filename = f"bdgd_staging_{run_id}_{layer_name}.tsv"
        path = self.base_dir / filename
        self._tracked_files.append(path)
        return path

    def extract_to_geoparquet(
        self,
        vsi_path: str,
        layer_name: str,
        output_parquet: Path,
    ) -> tuple[int, int]:
        """Extracts a single layer from the GDAL VSI ZIP directly to GeoParquet using DuckDB C++ engine.

        Returns
        -------
        tuple[int, int]
            (feature_count, file_size_bytes)
        """
        norm_parquet = str(output_parquet).replace("\\", "/")
        norm_vsi = vsi_path.replace("\\", "/")

        con = duckdb.connect()
        try:
            con.execute("INSTALL spatial; LOAD spatial;")
            # Fast streaming extraction directly from VSI into Parquet
            con.execute(f"""
                COPY (
                    SELECT * FROM ST_Read('{norm_vsi}', layer='{layer_name}')
                ) TO '{norm_parquet}' (FORMAT PARQUET)
            """)

            # Get row count from Parquet metadata
            count_res = con.execute(
                f"SELECT count(*) FROM read_parquet('{norm_parquet}')"
            ).fetchone()
            row_count = count_res[0] if count_res else 0
            size_bytes = output_parquet.stat().st_size

            logger.info(
                "[%s] Extraído para GeoParquet intermediário: %d feições (%s)",
                layer_name,
                row_count,
                f"{size_bytes / (1024 * 1024):.2f} MB",
            )
            return row_count, size_bytes
        finally:
            con.close()

    def cleanup_layer(self, *paths: Path | None) -> None:
        """Removes temporary files for a specific layer after load is confirmed."""
        if not self.auto_cleanup:
            return

        for p in paths:
            if p and p.exists():
                try:
                    os.remove(p)
                    logger.debug("Arquivo temporário removido com sucesso: %s", p)
                except OSError as exc:
                    logger.warning("Falha ao remover arquivo temporário %s: %s", p, exc)

    def cleanup_all(self) -> None:
        """Removes all tracked files."""
        if not self.auto_cleanup:
            return
        for p in self._tracked_files:
            if p.exists():
                try:
                    os.remove(p)
                except OSError:
                    pass
        self._tracked_files.clear()
