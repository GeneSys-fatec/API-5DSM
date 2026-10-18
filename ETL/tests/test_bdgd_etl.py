"""
test_bdgd_etl.py — Unit and integration tests for the high-performance bdgd_etl package.
"""
from __future__ import annotations

import tempfile
import zipfile
from pathlib import Path
import pytest
import duckdb

from bdgd_etl.config import ETLConfig, PipelineConfig, load_config
from bdgd_etl.gdal_vsi import filter_layers, resolve_vsi_path
from bdgd_etl.idempotency import compute_file_sha256
from bdgd_etl.parquet_storage import ParquetStage
from bdgd_etl.telemetry import LayerMetrics, MemoryTracker


def test_load_config_defaults(tmp_path: Path):
    toml_file = tmp_path / "test_config.toml"
    toml_file.write_text("""
    [pipeline]
    distribuidora = "TEST_DIST"
    workers = 8
    force = true
    include_layers = ["UCBT", "POSTE"]

    [database]
    schema = "test_schema"
    """)

    cfg = load_config(toml_file)
    assert cfg.pipeline.distribuidora == "TEST_DIST"
    assert cfg.pipeline.workers == 8
    assert cfg.pipeline.force is True
    assert cfg.pipeline.include_layers == ["UCBT", "POSTE"]
    assert cfg.database.schema == "test_schema"


def test_filter_layers_fallback_and_discovery():
    available = ["SSDAT", "SSDBT", "PONNOT", "SUB"]
    fallbacks = {
        "POSTE": {
            "layer": "PONNOT",
            "filter_col": "TIP_PN",
            "filter_value": "POS",
        }
    }

    # 1. Automatic discovery (include_layers is empty -> returns all)
    res_all = filter_layers(available, include_layers=[], exclude_layers=["SUB"])
    assert len(res_all) == 3
    assert ("SUB", None) not in res_all

    # 2. Explicit request with fallback mapping (POSTE -> PONNOT)
    res_req = filter_layers(
        available,
        include_layers=["POSTE", "SSDAT"],
        fallbacks=fallbacks,
    )
    assert len(res_req) == 2
    assert ("PONNOT", "POSTE") in res_req
    assert ("SSDAT", "SSDAT") in res_req


def test_sha256_computation(tmp_path: Path):
    sample_file = tmp_path / "sample.bin"
    sample_file.write_bytes(b"HELLO_BDGD_ETL_PIPELINE")
    digest = compute_file_sha256(sample_file)
    assert len(digest) == 64
    assert digest == compute_file_sha256(sample_file)


def test_memory_tracker():
    with MemoryTracker() as tracker:
        # Allocate some memory
        data = [i for i in range(100_000)]
        del data
        tracker.snapshot()
        assert tracker.elapsed_s >= 0.0


def test_parquet_stage_cleanup(tmp_path: Path):
    stage = ParquetStage(temp_base_dir=tmp_path, auto_cleanup=True)
    p_path = stage.get_parquet_path("test_layer", "run1")
    p_path.write_text("DUMMY_PARQUET_DATA")
    assert p_path.exists()

    stage.cleanup_layer(p_path)
    assert not p_path.exists()


def test_resolve_vsi_path_from_zip(tmp_path: Path):
    zip_path = tmp_path / "test.zip"
    with zipfile.ZipFile(zip_path, "w") as zf:
        zf.writestr("MyData.gdb/a00000001.gdbtable", "dummy")

    vsi_path, container = resolve_vsi_path(zip_path)
    assert "/vsizip/" in vsi_path
    assert "MyData.gdb" in vsi_path
    assert container == "MyData.gdb"
