"""
bdgd_etl.config — Configuration management for the BDGD ETL pipeline.
Loads settings from TOML, environment variables, or CLI overrides.
"""
from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

try:
    import tomllib  # Python 3.11+
except ImportError:
    import tomli as tomllib  # type: ignore

from dotenv import load_dotenv

load_dotenv()


@dataclass
class PipelineConfig:
    zip_path: str = ""
    distribuidora: str = "DIST"
    regiao: str = "BR"
    workers: int = 4
    force: bool = False
    include_layers: list[str] = field(default_factory=list)
    exclude_layers: list[str] = field(default_factory=list)


@dataclass
class DatabaseConfig:
    type: str = "postgres"  # postgres | mysql
    url: str = os.getenv("BDGD_DB_URL", "postgresql://postgres:123@localhost:5432/bdgd")
    schema: str = "bdgd"
    target_srid: int = 4326
    source_srid_fallback: int = 4674


@dataclass
class StorageConfig:
    temp_dir: str = ""
    cleanup_temp: bool = True
    keep_temp_on_error: bool = False


@dataclass
class LoggingConfig:
    level: str = "INFO"
    structured_json: bool = False


@dataclass
class ETLConfig:
    pipeline: PipelineConfig = field(default_factory=PipelineConfig)
    database: DatabaseConfig = field(default_factory=DatabaseConfig)
    storage: StorageConfig = field(default_factory=StorageConfig)
    logging: LoggingConfig = field(default_factory=LoggingConfig)

    # Standard ANEEL BDGD fallbacks (e.g. POSTE was merged into PONNOT in BDGD v1.0/v1.1)
    layer_fallbacks: dict[str, dict[str, str]] = field(
        default_factory=lambda: {
            "POSTE": {
                "layer": "PONNOT",
                "filter_col": "TIP_PN",
                "filter_value": "POS",
            }
        }
    )


def load_config(config_path: str | Path | None = None) -> ETLConfig:
    """Loads configuration from a TOML file if present, merged with environment defaults."""
    cfg = ETLConfig()

    data: dict[str, Any] = {}
    if config_path:
        path = Path(config_path)
        if path.exists():
            with open(path, "rb") as f:
                data = tomllib.load(f)
    else:
        # Check standard default locations
        default_toml = Path("config.toml")
        if default_toml.exists():
            with open(default_toml, "rb") as f:
                data = tomllib.load(f)

    # Pipeline section
    p_data = data.get("pipeline", {})
    if "zip_path" in p_data:
        cfg.pipeline.zip_path = str(p_data["zip_path"])
    if "distribuidora" in p_data:
        cfg.pipeline.distribuidora = str(p_data["distribuidora"])
    if "regiao" in p_data:
        cfg.pipeline.regiao = str(p_data["regiao"])
    if "workers" in p_data:
        cfg.pipeline.workers = int(p_data["workers"])
    if "force" in p_data:
        cfg.pipeline.force = bool(p_data["force"])
    if "include_layers" in p_data:
        cfg.pipeline.include_layers = list(p_data["include_layers"])
    if "exclude_layers" in p_data:
        cfg.pipeline.exclude_layers = list(p_data["exclude_layers"])

    # Database section
    d_data = data.get("database", {})
    if "type" in d_data:
        cfg.database.type = str(d_data["type"]).lower()
    if "url" in d_data:
        cfg.database.url = str(d_data["url"])
    # Environment variable overrides
    env_db = os.getenv("BDGD_DB_URL")
    if env_db:
        cfg.database.url = env_db

    if "schema" in d_data:
        cfg.database.schema = str(d_data["schema"])
    if "target_srid" in d_data:
        cfg.database.target_srid = int(d_data["target_srid"])
    if "source_srid_fallback" in d_data:
        cfg.database.source_srid_fallback = int(d_data["source_srid_fallback"])

    # Storage section
    s_data = data.get("storage", {})
    if "temp_dir" in s_data:
        cfg.storage.temp_dir = str(s_data["temp_dir"])
    if "cleanup_temp" in s_data:
        cfg.storage.cleanup_temp = bool(s_data["cleanup_temp"])
    if "keep_temp_on_error" in s_data:
        cfg.storage.keep_temp_on_error = bool(s_data["keep_temp_on_error"])

    # Logging section
    l_data = data.get("logging", {})
    if "level" in l_data:
        cfg.logging.level = str(l_data["level"]).upper()
    if "structured_json" in l_data:
        cfg.logging.structured_json = bool(l_data["structured_json"])

    return cfg
