"""
bdgd_etl.pipeline — Parallel orchestration engine for the BDGD ETL.
Coordinates GDAL /vsizip/ extraction, intermediate GeoParquet staging,
DuckDB spatial transformations, PostgreSQL bulk loading, idempotency tracking,
and per-layer memory cleanup.
"""
from __future__ import annotations

import concurrent.futures
import gc
import logging
import os
import sys
import uuid
from pathlib import Path
from typing import Any

from .bulk_loader import create_bulk_loader
from .config import ETLConfig
from .duckdb_transform import transform_geoparquet_to_staging
from .gdal_vsi import discover_all_layers, filter_layers, resolve_vsi_path
from .idempotency import IdempotencyManager, compute_file_sha256
from .parquet_storage import ParquetStage
from .telemetry import LayerMetrics, MemoryTracker, print_summary_table

logger = logging.getLogger(__name__)


def process_single_layer_task(args: dict[str, Any]) -> LayerMetrics:
    """Worker task executed per layer. Fully self-contained and picklable for ProcessPoolExecutor."""
    vsi_path = args["vsi_path"]
    layer_name = args["layer_name"]
    target_name = args["target_name"]
    file_hash = args["file_hash"]
    file_name = args["file_name"]
    distribuidora = args["distribuidora"]
    regiao = args["regiao"]
    db_type = args["db_type"]
    db_url = args["db_url"]
    schema = args["schema"]
    target_srid = args["target_srid"]
    source_srid = args["source_srid"]
    filter_spec = args["filter_spec"]
    temp_dir = args["temp_dir"]
    auto_cleanup = args["auto_cleanup"]
    keep_temp_on_error = args["keep_temp_on_error"]
    force = args["force"]
    run_id = args["run_id"]
    structured_json = args.get("structured_json", False)

    # 1. Idempotency Check
    idempotency_mgr = IdempotencyManager(db_url=db_url, schema=schema)
    if not force:
        if idempotency_mgr.is_layer_processed(file_hash, target_name):
            logger.info(
                "[%s] Layer já processada anteriormente (hash %s). Pulando (use --force para reprocessar).",
                target_name,
                file_hash[:12],
            )
            metric = LayerMetrics(
                layer=layer_name,
                target_layer=target_name,
                rows=0,
                elapsed_s=0.0,
                peak_memory_mb=0.0,
                status="SKIPPED",
            )
            if structured_json:
                print(f"JSON_METRIC: {metric.to_json()}")
            return metric

    stage = ParquetStage(temp_base_dir=temp_dir, auto_cleanup=auto_cleanup)
    parquet_path = stage.get_parquet_path(target_name, run_id)
    staging_tsv_path = stage.get_staging_tsv_path(target_name, run_id)

    # 2. Process Layer with Peak Memory & Elapsed Time Tracking
    with MemoryTracker() as tracker:
        try:
            logger.info("=== [%s -> %s] Iniciando extração e transformação ===", layer_name, target_name)

            # Step A: Direct /vsizip/ extraction to GeoParquet
            _, _ = stage.extract_to_geoparquet(vsi_path, layer_name, parquet_path)

            # Step B: DuckDB Spatial transformations & TSV staging
            valid_rows = transform_geoparquet_to_staging(
                parquet_path=parquet_path,
                staging_tsv_path=staging_tsv_path,
                layer_name=layer_name,
                target_layer_name=target_name,
                distribuidora=distribuidora,
                regiao=regiao,
                source_srid=source_srid,
                target_srid=target_srid,
                filter_spec=filter_spec,
            )

            # Step C: Bulk Load (COPY FROM STDIN) into Target Database
            loader = create_bulk_loader(
                db_type=db_type,
                db_url=db_url,
                schema=schema,
                target_srid=target_srid,
            )
            try:
                loaded_rows = loader.bulk_load(table_name=target_name, staging_tsv_path=staging_tsv_path)
            finally:
                loader.close()

            # Step D: Cleanup intermediate files immediately
            stage.cleanup_layer(parquet_path, staging_tsv_path)

            # Step E: Record Success in Idempotency Tracking Table
            tracker.snapshot()
            idempotency_mgr.record_result(
                file_hash=file_hash,
                file_name=file_name,
                layer_name=target_name,
                feature_count=loaded_rows,
                elapsed_s=tracker.elapsed_s,
                peak_memory_mb=tracker.peak_memory_mb,
                status="SUCCESS",
            )

            metric = LayerMetrics(
                layer=layer_name,
                target_layer=target_name,
                rows=loaded_rows,
                elapsed_s=tracker.elapsed_s,
                peak_memory_mb=tracker.peak_memory_mb,
                status="SUCCESS",
            )

        except Exception as exc:
            logger.error("[%s] FALHA no processamento da layer: %s", target_name, exc, exc_info=True)
            if not keep_temp_on_error:
                stage.cleanup_layer(parquet_path, staging_tsv_path)

            tracker.snapshot()
            idempotency_mgr.record_result(
                file_hash=file_hash,
                file_name=file_name,
                layer_name=target_name,
                feature_count=0,
                elapsed_s=tracker.elapsed_s,
                peak_memory_mb=tracker.peak_memory_mb,
                status="FAILED",
                error_message=str(exc),
            )

            metric = LayerMetrics(
                layer=layer_name,
                target_layer=target_name,
                rows=0,
                elapsed_s=tracker.elapsed_s,
                peak_memory_mb=tracker.peak_memory_mb,
                status="FAILED",
                error=str(exc),
            )

        finally:
            # Explicit memory release between layers
            gc.collect()

    if structured_json:
        print(f"JSON_METRIC: {metric.to_json()}")

    return metric


def run_pipeline(cfg: ETLConfig) -> list[LayerMetrics]:
    """Main pipeline execution orchestrator."""
    zip_path = Path(cfg.pipeline.zip_path).resolve()
    if not zip_path.exists():
        raise FileNotFoundError(f"Arquivo BDGD não encontrado: {zip_path}")

    # 1. Compute SHA-256 for Idempotency
    logger.info("Calculando hash SHA-256 do arquivo BDGD: %s ...", zip_path.name)
    file_hash = compute_file_sha256(zip_path)
    logger.info("Hash SHA-256: %s", file_hash)

    # 2. Resolve GDAL /vsizip/ path
    vsi_path, container_name = resolve_vsi_path(zip_path)

    # 3. Dynamic Discovery of All Layers
    all_discovered = discover_all_layers(vsi_path)

    # 4. Filter layers (includes all if include_layers is empty)
    selected_layers = filter_layers(
        available_layers=all_discovered,
        include_layers=cfg.pipeline.include_layers,
        exclude_layers=cfg.pipeline.exclude_layers,
        fallbacks=cfg.layer_fallbacks,
    )

    if not selected_layers:
        logger.warning("Nenhuma layer selecionada para processamento. Finalizando.")
        return []

    logger.info(
        "Layers agendadas para execução (%d): %s",
        len(selected_layers),
        [target or actual for actual, target in selected_layers],
    )

    # 5. Ensure Idempotency state table in Database
    idempotency_mgr = IdempotencyManager(db_url=cfg.database.url, schema=cfg.database.schema)
    idempotency_mgr.ensure_state_table()

    # 6. Build Task Arguments
    run_id = uuid.uuid4().hex[:8]
    tasks_args: list[dict[str, Any]] = []

    for actual_layer, target_alias in selected_layers:
        target_name = target_alias or actual_layer
        # Check if fallback filter applies
        fallback_spec = None
        if target_alias and target_alias.upper() in cfg.layer_fallbacks:
            fallback_spec = cfg.layer_fallbacks[target_alias.upper()]

        args = {
            "vsi_path": vsi_path,
            "layer_name": actual_layer,
            "target_name": target_name,
            "file_hash": file_hash,
            "file_name": zip_path.name,
            "distribuidora": cfg.pipeline.distribuidora,
            "regiao": cfg.pipeline.regiao,
            "db_type": cfg.database.type,
            "db_url": cfg.database.url,
            "schema": cfg.database.schema,
            "target_srid": cfg.database.target_srid,
            "source_srid": cfg.database.source_srid_fallback,
            "filter_spec": fallback_spec,
            "temp_dir": cfg.storage.temp_dir,
            "auto_cleanup": cfg.storage.cleanup_temp,
            "keep_temp_on_error": cfg.storage.keep_temp_on_error,
            "force": cfg.pipeline.force,
            "run_id": run_id,
            "structured_json": cfg.logging.structured_json,
        }
        tasks_args.append(args)

    # 7. Execute Tasks (Parallel or Sequential)
    workers = max(1, cfg.pipeline.workers)
    results: list[LayerMetrics] = []

    logger.info("Iniciando execução do pipeline com %d worker(s)...", workers)

    if workers == 1 or len(tasks_args) == 1:
        # Sequential execution
        for args in tasks_args:
            res = process_single_layer_task(args)
            results.append(res)
    else:
        # Multiprocessing execution via ProcessPoolExecutor
        with concurrent.futures.ProcessPoolExecutor(max_workers=workers) as executor:
            future_to_layer = {
                executor.submit(process_single_layer_task, args): args["target_name"]
                for args in tasks_args
            }

            for future in concurrent.futures.as_completed(future_to_layer):
                layer = future_to_layer[future]
                try:
                    res = future.result()
                    results.append(res)
                except Exception as exc:
                    logger.error("Erro fatal no worker da layer %s: %s", layer, exc)
                    results.append(
                        LayerMetrics(
                            layer=layer,
                            target_layer=layer,
                            rows=0,
                            elapsed_s=0.0,
                            peak_memory_mb=0.0,
                            status="FAILED",
                            error=str(exc),
                        )
                    )

    # 8. Render Structured Summary Table
    print_summary_table(results)

    return results
