"""
main.py — Orquestrador do pipeline ETL da BDGD.

Compatível com execuções legadas e com o novo motor otimizado:
- Leitura direta de arquivos .zip (múltiplos GB) via GDAL /vsizip/ (sem extração em disco)
- Descoberta automática de todas as layers do GDB
- Paralelização configurável por camada (multiprocessing)
- Conversão intermediária para GeoParquet por camada
- Transformações espaciais vetorizadas via DuckDB + spatial extension (reprojeção EPSG:4326, filtros, chaves)
- Carga final por bulk load de alto desempenho (PostgreSQL COPY FROM STDIN + staging table)
- Idempotência baseada em hash SHA-256 do arquivo + camada
- Telemetria de pico de RAM (tracemalloc) e tempo

Uso:
    python main.py <caminho.zip_ou_gdb> <DISTRIBUIDORA> <REGIAO> [--layers ...] [--workers ...] [--force]
    python main.py --config config.toml
"""
from __future__ import annotations

import argparse
import sys
from bdgd_etl.cli import main as cli_main


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Parser compatível com as especificações e testes legados."""
    parser = argparse.ArgumentParser(
        description="Pipeline ETL para importar dados da BDGD no PostGIS.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    # Check if --config is in argv
    check_argv = argv if argv is not None else sys.argv[1:]
    has_config = any(arg in ("-c", "--config") for arg in check_argv)

    if has_config:
        parser.add_argument("gdb_path", nargs="?", default=None, metavar="CAMINHO.GDB")
        parser.add_argument("distribuidora", nargs="?", default=None, metavar="NOME_DISTRIBUIDORA")
        parser.add_argument("regiao", nargs="?", default=None, metavar="REGIAO")
    else:
        parser.add_argument("gdb_path", metavar="CAMINHO.GDB", help="Caminho para o arquivo .gdb ou .zip da BDGD.")
        parser.add_argument("distribuidora", metavar="NOME_DISTRIBUIDORA", help="Sigla da distribuidora.")
        parser.add_argument("regiao", metavar="REGIAO", help="Região associada aos ativos.")

    parser.add_argument("-c", "--config", dest="config_path", default=None, help="Caminho para arquivo TOML.")
    parser.add_argument("-w", "--workers", dest="workers", type=int, default=None, help="Número de workers.")
    parser.add_argument("--layers", nargs="+", default=None, metavar="LAYER", help="Processa apenas as layers especificadas.")
    parser.add_argument("--exclude", nargs="+", default=None, metavar="LAYER", help="Layers a excluir.")
    parser.add_argument("-f", "--force", dest="force", action="store_true", default=None, help="Forçar reprocessamento.")
    parser.add_argument("--db-url", default=None, help="Connection string do banco de destino.")
    parser.add_argument("--db-type", choices=["postgres", "mysql"], default="postgres", help="Tipo de banco.")
    parser.add_argument("--log-level", default="INFO", choices=["DEBUG", "INFO", "WARNING", "ERROR"], help="Nível de log.")
    parser.add_argument("--json", dest="json", action="store_true", default=None, help="Saída estruturada JSON.")
    parser.add_argument("--import-id", default=None, help="ID da importação no backend.")

    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    cli_args = []
    if args.config_path:
        cli_args.extend(["--config", args.config_path])
    if args.gdb_path:
        cli_args.append(args.gdb_path)
    if args.distribuidora:
        cli_args.append(args.distribuidora)
    if args.regiao:
        cli_args.append(args.regiao)
    if args.workers is not None:
        cli_args.extend(["--workers", str(args.workers)])
    if args.layers:
        cli_args.extend(["--layers", *args.layers])
    if args.exclude:
        cli_args.extend(["--exclude", *args.exclude])
    if args.force:
        cli_args.append("--force")
    if args.db_url:
        cli_args.extend(["--db-url", args.db_url])
    if args.db_type:
        cli_args.extend(["--db-type", args.db_type])
    if args.log_level:
        cli_args.extend(["--log-level", args.log_level])
    if args.json:
        cli_args.append("--json")
    if args.import_id:
        cli_args.extend(["--import-id", args.import_id])

    return cli_main(cli_args)


if __name__ == "__main__":
    sys.exit(main())
