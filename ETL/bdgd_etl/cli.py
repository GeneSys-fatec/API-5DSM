"""
bdgd_etl.cli — Command-Line Interface for the BDGD ETL pipeline.
Provides full parameterization via flags, TOML configuration files, and environment variables.
"""
from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

from .config import ETLConfig, load_config
from .pipeline import run_pipeline


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="bdgd-etl",
        description="Pipeline ETL de Alta Performance para Geodatabase BDGD (ZIP) com DuckDB e PostgreSQL COPY.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        "zip_path",
        nargs="?",
        default=None,
        metavar="CAMINHO_ZIP_OU_GDB",
        help="Caminho para o arquivo ZIP (múltiplos GB) contendo o .gdb ou pasta .gdb.",
    )
    parser.add_argument(
        "distribuidora",
        nargs="?",
        default=None,
        metavar="DISTRIBUIDORA",
        help="Sigla da distribuidora (ex: EDP_SP, CEMIG, ENEL).",
    )
    parser.add_argument(
        "regiao",
        nargs="?",
        default=None,
        metavar="REGIAO",
        help="Região de cobertura dos ativos (ex: SUDESTE, SUL).",
    )

    # Optional configuration flags
    parser.add_argument(
        "-c", "--config",
        dest="config_path",
        default=None,
        help="Caminho para o arquivo de configuração TOML (ex: config.toml).",
    )
    parser.add_argument(
        "-w", "--workers",
        dest="workers",
        type=int,
        default=None,
        help="Número de workers para paralelização por camada (default: 4 ou do config).",
    )
    parser.add_argument(
        "-l", "--layers",
        dest="layers",
        nargs="+",
        default=None,
        metavar="LAYER",
        help="Subconjunto de layers a processar (default: descobre e processa TODAS as layers automaticamente).",
    )
    parser.add_argument(
        "--exclude",
        dest="exclude",
        nargs="+",
        default=None,
        metavar="LAYER",
        help="Layers a excluir do processamento.",
    )
    parser.add_argument(
        "-f", "--force",
        dest="force",
        action="store_true",
        default=None,
        help="Força o reprocessamento das camadas mesmo se o hash SHA-256 for idêntico.",
    )
    parser.add_argument(
        "--db-url",
        dest="db_url",
        default=None,
        help="URL de conexão ao banco de dados (PostgreSQL / MySQL).",
    )
    parser.add_argument(
        "--db-type",
        dest="db_type",
        choices=["postgres", "mysql"],
        default=None,
        help="Tipo do banco de destino (default: postgres).",
    )
    parser.add_argument(
        "--log-level",
        dest="log_level",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        default=None,
        help="Nível de log (default: INFO).",
    )
    parser.add_argument(
        "--json",
        dest="json",
        action="store_true",
        default=None,
        help="Ativa saída estruturada JSON de telemetria por camada.",
    )

    return parser


def setup_logging(level_name: str) -> None:
    logging.basicConfig(
        level=getattr(logging, level_name.upper(), logging.INFO),
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    # 1. Load base configuration from TOML (if provided or default)
    cfg: ETLConfig = load_config(args.config_path)

    # 2. CLI positional overrides
    if args.zip_path:
        cfg.pipeline.zip_path = args.zip_path
    if args.distribuidora:
        cfg.pipeline.distribuidora = args.distribuidora
    if args.regiao:
        cfg.pipeline.regiao = args.regiao

    # 3. CLI options overrides
    if args.workers is not None:
        cfg.pipeline.workers = args.workers
    if args.layers is not None:
        cfg.pipeline.include_layers = args.layers
    if args.exclude is not None:
        cfg.pipeline.exclude_layers = args.exclude
    if args.force is not None:
        cfg.pipeline.force = args.force
    if args.db_url is not None:
        cfg.database.url = args.db_url
    if args.db_type is not None:
        cfg.database.type = args.db_type
    if args.log_level is not None:
        cfg.logging.level = args.log_level
    if args.json is not None:
        cfg.logging.structured_json = args.json

    setup_logging(cfg.logging.level)

    # Validate that we have a zip_path
    if not cfg.pipeline.zip_path:
        parser.print_help()
        print("\n[ERRO] O caminho do arquivo BDGD (.zip ou .gdb) é obrigatório via argumento ou config.toml.")
        return 1

    try:
        metrics = run_pipeline(cfg)
        if not metrics:
            return 0
        all_success = all(m.status in ("SUCCESS", "SKIPPED") for m in metrics)
        return 0 if all_success else 1
    except Exception as exc:
        logging.getLogger("bdgd_etl").error("Falha na execução do pipeline: %s", exc, exc_info=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
