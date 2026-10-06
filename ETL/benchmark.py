"""
benchmark.py — Benchmark comparativo entre o Pipeline ETL Original e o Novo Pipeline Otimizado.
Compara tempo de execução, pico de memória RAM (tracemalloc / RSS), e taxa de transferência (rows/s).
"""
from __future__ import annotations

import gc
import os
import sys
import time
import tracemalloc
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).parent.resolve()
sys.path.insert(0, str(BASE_DIR))

import config as legacy_config
import extract as legacy_extract
import transform as legacy_transform
import load as legacy_load

from bdgd_etl.config import ETLConfig, PipelineConfig
from bdgd_etl.pipeline import run_pipeline


def benchmark_legacy(gdb_path: str, layer_name: str, dist_name: str, regiao: str, db_url: str):
    print(f"\n[BENCHMARK] Executando Pipeline ORIGINAL para layer '{layer_name}'...")
    gc.collect()
    tracemalloc.start()
    t0 = time.perf_counter()

    engine = legacy_load.get_engine(db_url)
    legacy_load.ensure_schema(engine, legacy_config.SCHEMA)

    # 1. Extract
    gdf = legacy_extract.read_layer(gdb_path, layer_name)
    key_col = "COD_ID" if "COD_ID" in gdf.columns else "OBJECTID"

    # 2. Transform (Pandas / Shapely)
    gdf = legacy_transform.prepare_layer(
        gdf,
        layer_name=layer_name,
        dist_name=dist_name,
        key_col=key_col,
        target_crs=legacy_config.TARGET_CRS,
        source_crs_fallback=legacy_config.SOURCE_CRS_FALLBACK,
    )
    gdf["tipo_ativo"] = layer_name
    gdf["distribuidora"] = dist_name
    gdf["regiao"] = regiao

    # 3. Load (SQLAlchemy batch inserts)
    rows = legacy_load.upsert_layer(
        gdf,
        layer_name=layer_name,
        key_col=key_col,
        engine=engine,
        pg_schema=legacy_config.SCHEMA,
    )

    t1 = time.perf_counter()
    _, peak = tracemalloc.get_traced_memory()
    tracemalloc.stop()
    gc.collect()

    elapsed = t1 - t0
    peak_mb = peak / (1024 * 1024)
    print(f"  -> Pipeline Original: {rows} feições em {elapsed:.2f}s | Pico de RAM: {peak_mb:.1f} MB | Taxa: {rows / elapsed:.1f} rows/s")
    return {"rows": rows, "elapsed_s": elapsed, "peak_ram_mb": peak_mb}


def benchmark_optimized(zip_path: str, layer_name: str, dist_name: str, regiao: str, db_url: str):
    print(f"\n[BENCHMARK] Executando NOVO Pipeline Otimizado para layer '{layer_name}'...")
    gc.collect()
    tracemalloc.start()
    t0 = time.perf_counter()

    cfg = ETLConfig(
        pipeline=PipelineConfig(
            zip_path=zip_path,
            distribuidora=dist_name,
            regiao=regiao,
            workers=1,
            force=True,
            include_layers=[layer_name],
        )
    )
    cfg.database.url = db_url

    metrics = run_pipeline(cfg)

    t1 = time.perf_counter()
    _, peak = tracemalloc.get_traced_memory()
    tracemalloc.stop()
    gc.collect()

    res = metrics[0] if metrics else None
    rows = res.rows if res else 0
    elapsed = t1 - t0
    peak_mb = peak / (1024 * 1024)
    print(f"  -> Novo Pipeline: {rows} feições em {elapsed:.2f}s | Pico de RAM: {peak_mb:.1f} MB | Taxa: {rows / elapsed:.1f} rows/s")
    return {"rows": rows, "elapsed_s": elapsed, "peak_ram_mb": peak_mb}


def main():
    zip_path = r"D:/Programacao/API-5DSM/uploads/bdgd/EDP/2026-09-18/39a899b4-f28c-438e-8f9e-57282d331266-EDP_SP_391_2024-12-31_V11_20250831-1845.gdb.zip"
    extracted_gdb = r"D:/Programacao/API-5DSM/uploads/bdgd/EDP/2026-09-18/EDP_SP_391_2024-12-31_V11_20250831-1845.gdb"
    db_url = "postgresql://postgres:123@localhost:5432/bdgd"
    layer = "SSDAT"

    print("=" * 70)
    print("  BENCHMARK: PIPELINE ORIGINAL (Pandas/SQLAlchemy) vs NOVO (DuckDB/COPY)")
    print("=" * 70)
    print(f"Layer de teste: {layer}")
    print(f"Arquivo ZIP: {Path(zip_path).name}")

    orig = benchmark_legacy(extracted_gdb, layer, "EDP_SP", "SUDESTE", db_url)
    opt = benchmark_optimized(zip_path, layer, "EDP_SP", "SUDESTE", db_url)

    speedup = orig["elapsed_s"] / opt["elapsed_s"] if opt["elapsed_s"] > 0 else 1.0
    mem_saving = (1.0 - (opt["peak_ram_mb"] / orig["peak_ram_mb"])) * 100 if orig["peak_ram_mb"] > 0 else 0.0

    print("\n" + "=" * 70)
    print("                       RESULTADOS DO BENCHMARK")
    print("=" * 70)
    print(f"{'MÉTRICA':<28} {'ORIGINAL':>18} {'NOVO OTIMIZADO':>18}")
    print("-" * 70)
    print(f"{'Tempo de execução (s)':<28} {orig['elapsed_s']:>18.2f} {opt['elapsed_s']:>18.2f}")
    print(f"{'Pico de memória RAM (MB)':<28} {orig['peak_ram_mb']:>18.1f} {opt['peak_ram_mb']:>18.1f}")
    print(f"{'Throughput (feições/seg)':<28} {orig['rows'] / orig['elapsed_s']:>18.1f} {opt['rows'] / opt['elapsed_s']:>18.1f}")
    print(f"{'Extração em disco do ZIP':<28} {'OBRIGATÓRIA':>18} {'ZERO (Direto)':>18}")
    print("-" * 70)
    print(f"Ganho de Velocidade (Speedup): {speedup:.2f}x mais rápido")
    print(f"Redução de Consumo de RAM:    {mem_saving:.1f}% de economia de memória")
    print("=" * 70 + "\n")


if __name__ == "__main__":
    main()
