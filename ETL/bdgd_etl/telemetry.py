"""
bdgd_etl.telemetry — Structured telemetry, memory tracking, and execution reporting.
Tracks peak memory usage (tracemalloc / psutil), elapsed time, feature count,
and formats structured JSON logs and terminal summary tables.
"""
from __future__ import annotations

import json
import logging
import os
import time
import tracemalloc
from dataclasses import asdict, dataclass
from typing import Optional

try:
    import psutil
except ImportError:
    psutil = None  # type: ignore

logger = logging.getLogger(__name__)


@dataclass
class LayerMetrics:
    layer: str
    target_layer: str
    rows: int = 0
    elapsed_s: float = 0.0
    peak_memory_mb: float = 0.0
    status: str = "SUCCESS"  # SUCCESS | SKIPPED | FAILED
    error: Optional[str] = None

    def to_json(self) -> str:
        data = asdict(self)
        data["timestamp"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        return json.dumps(data, ensure_ascii=False)


class MemoryTracker:
    """Measures peak memory usage during execution of a block of code."""

    def __init__(self):
        self.elapsed_s: float = 0.0
        self.peak_memory_mb: float = 0.0
        self._start_time: float = 0.0
        self._proc = None

    def __enter__(self):
        tracemalloc.start()
        self._start_time = time.perf_counter()
        if psutil:
            try:
                self._proc = psutil.Process(os.getpid())
            except Exception:
                self._proc = None
        return self

    def snapshot(self):
        self.elapsed_s = time.perf_counter() - self._start_time
        if tracemalloc.is_tracing():
            _, peak = tracemalloc.get_traced_memory()
            peak_mb = peak / (1024 * 1024)
            if self._proc:
                try:
                    rss_mb = self._proc.memory_info().rss / (1024 * 1024)
                    peak_mb = max(peak_mb, rss_mb)
                except Exception:
                    pass
            self.peak_memory_mb = peak_mb

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.snapshot()
        if tracemalloc.is_tracing():
            tracemalloc.stop()


def print_summary_table(metrics_list: list[LayerMetrics]) -> None:
    """Renders a clean summary table with metrics per layer."""
    col_layer = 14
    col_rows = 10
    col_time = 10
    col_mem = 12
    col_status = 30

    header = (
        f"{'LAYER':<{col_layer}} "
        f"{'FEIÇÕES':>{col_rows}} "
        f"{'TEMPO(s)':>{col_time}} "
        f"{'PICO RAM':>{col_mem}}  "
        f"STATUS"
    )
    sep = "=" * (col_layer + col_rows + col_time + col_mem + col_status + 6)
    sub_sep = "-" * len(sep)

    print()
    print(sep)
    print("           RESUMO DO PIPELINE ETL BDGD (HIGH-PERFORMANCE)")
    print(sep)
    print(header)
    print(sub_sep)

    total_rows = 0
    total_time = 0.0
    max_peak_ram = 0.0
    all_ok = True

    for m in metrics_list:
        total_rows += m.rows
        total_time += m.elapsed_s
        max_peak_ram = max(max_peak_ram, m.peak_memory_mb)

        status_str = m.status
        if m.error:
            # Shorten error if too long for table
            err_short = m.error.splitlines()[0][:26] + "..." if len(m.error) > 28 else m.error
            status_str = f"{m.status}: {err_short}"

        if m.status == "FAILED":
            all_ok = False

        print(
            f"{m.layer:<{col_layer}} "
            f"{m.rows:>{col_rows}} "
            f"{m.elapsed_s:>{col_time}.2f} "
            f"{f'{m.peak_memory_mb:.1f} MB':>{col_mem}}  "
            f"{status_str}"
        )

    print(sub_sep)
    status_summary = "CONCLUÍDO COM SUCESSO" if all_ok else "CONCLUÍDO COM FALHAS"
    print(
        f"{'TOTAL':<{col_layer}} "
        f"{total_rows:>{col_rows}} "
        f"{total_time:>{col_time}.2f} "
        f"{f'{max_peak_ram:.1f} MB (máx)':>{col_mem}}  "
        f"{status_summary}"
    )
    print(sep)
    print()
