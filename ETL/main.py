from __future__ import annotations

import argparse
import logging
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import config
import extract
import transform
import load
import schema

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("bdgd_etl.main")


@dataclass
class LayerResult:
    layer: str
    rows: int = 0
    elapsed_s: float = 0.0
    status: str = "OK"
    error: Optional[str] = None


def resolve_key_col(gdf, layer_name: str) -> str:
    preferred = config.KEY_COLUMN_BY_LAYER.get(layer_name, "COD_ID")
    if preferred in gdf.columns:
        return preferred

    logger.warning(
        "Campo '%s' não encontrado em '%s'. Tentando fallback '%s'.",
        preferred, layer_name, config.KEY_COLUMN_FALLBACK,
    )

    if config.KEY_COLUMN_FALLBACK in gdf.columns:
        logger.warning(
            "Usando '%s' como campo chave para '%s'. "
            "Ajuste KEY_COLUMN_BY_LAYER em config.py para silenciar este aviso.",
            config.KEY_COLUMN_FALLBACK, layer_name,
        )
        return config.KEY_COLUMN_FALLBACK

    raise KeyError(
        f"Nenhum campo chave encontrado para layer '{layer_name}'. "
        f"Tentou: ['{preferred}', '{config.KEY_COLUMN_FALLBACK}']. "
        f"Colunas disponíveis: {list(gdf.columns)}"
    )


def process_layer(
    gdb_path: str,
    layer_name: str,
    engine,
    dist_name: str,
    regiao: str,
) -> LayerResult:
    result = LayerResult(layer=layer_name)
    t0 = time.perf_counter()

    try:
        logger.info("=== [%s] Extraindo …", layer_name)
        gdf = extract.read_layer(gdb_path, layer_name)

        key_col = resolve_key_col(gdf, layer_name)
        logger.info("[%s] Campo chave: '%s'", layer_name, key_col)

        logger.info("[%s] Transformando …", layer_name)
        gdf = transform.prepare_layer(
            gdf,
            layer_name=layer_name,
            dist_name=dist_name,
            key_col=key_col,
            target_crs=config.TARGET_CRS,
            source_crs_fallback=config.SOURCE_CRS_FALLBACK,
        )

        gdf["tipo_ativo"] = layer_name
        gdf["distribuidora"] = dist_name
        gdf["regiao"] = regiao

        logger.info("[%s] Carregando em '%s' …", layer_name, config.SCHEMA)
        rows = load.upsert_layer(
            gdf,
            layer_name=layer_name,
            key_col=key_col,
            engine=engine,
            pg_schema=config.SCHEMA,
        )

        result.rows = rows
        result.status = "OK"

    except Exception as exc:  # pylint: disable=broad-except
        result.status = "ERRO"
        result.error = str(exc)
        logger.error(
            "[%s] FALHA: %s",
            layer_name, exc,
            exc_info=True,
        )

    result.elapsed_s = time.perf_counter() - t0
    return result


def print_summary(results: list[LayerResult]) -> None:
    col_w = 10
    row_w = 8
    time_w = 10
    status_w = 50

    header = (
        f"{'LAYER':<{col_w}} {'LINHAS':>{row_w}} {'TEMPO(s)':>{time_w}}  STATUS"
    )
    sep = "-" * (col_w + row_w + time_w + status_w + 6)

    print()
    print("=" * len(sep))
    print("  RESUMO DO PIPELINE ETL BDGD")
    print("=" * len(sep))
    print(header)
    print(sep)

    all_ok = True
    for r in results:
        status_str = r.status if not r.error else f"{r.status}: {r.error}"
        print(
            f"{r.layer:<{col_w}} {r.rows:>{row_w}} {r.elapsed_s:>{time_w}.2f}  {status_str}"
        )
        if r.status != "OK":
            all_ok = False

    print(sep)
    total_rows = sum(r.rows for r in results)
    total_time = sum(r.elapsed_s for r in results)
    print(
        f"{'TOTAL':<{col_w}} {total_rows:>{row_w}} {total_time:>{time_w}.2f}  "
        f"{'CONCLUÍDO' if all_ok else 'CONCLUÍDO COM ERROS'}"
    )
    print("=" * len(sep))
    print()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Pipeline ETL para importar dados da BDGD no PostGIS.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "gdb_path",
        metavar="CAMINHO.GDB",
        help="Caminho para o arquivo .gdb da BDGD.",
    )
    parser.add_argument(
        "distribuidora",
        metavar="NOME_DISTRIBUIDORA",
        help="Sigla da distribuidora (ex: CEMIG, ENEL_SP). Usada como coluna de rastreabilidade.",
    )
    parser.add_argument(
        "regiao",
        metavar="REGIAO",
        help="Região associada aos ativos (ex: SUDESTE, SUL). Usada como coluna de rastreabilidade.",
    )
    parser.add_argument(
        "--layers",
        nargs="+",
        default=None,
        metavar="LAYER",
        help="Processa apenas as layers especificadas (default: todas em config.LAYERS).",
    )
    parser.add_argument(
        "--db-url",
        default=None,
        help="Connection string PostgreSQL (substitui BDGD_DB_URL e o default de config.py).",
    )
    parser.add_argument(
        "--log-level",
        default="INFO",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        help="Nível de log (default: INFO).",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    logging.getLogger().setLevel(getattr(logging, args.log_level))

    gdb_path = Path(args.gdb_path)
    if not gdb_path.exists():
        logger.error("Arquivo GDB não encontrado: %s", gdb_path)
        return 1

    db_url = args.db_url or config.DB_URL
    layers_to_process = args.layers or config.LAYERS

    logger.info("Iniciando ETL BDGD")
    logger.info("  GDB:           %s", gdb_path)
    logger.info("  Distribuidora: %s", args.distribuidora)
    logger.info("  Layers:        %s", layers_to_process)

    logger.info("Listando layers disponíveis no GDB …")
    try:
        available_layers = extract.list_available_layers(str(gdb_path))
    except RuntimeError as exc:
        logger.error("Não foi possível abrir o GDB: %s", exc)
        return 1

    layers_to_run = []
    for layer in layers_to_process:
        if layer in available_layers:
            layers_to_run.append(layer)
        else:
            logger.warning(
                "Layer '%s' não encontrada no GDB — será ignorada.", layer
            )

    if not layers_to_run:
        logger.error("Nenhuma das layers configuradas foi encontrada no GDB. Abortando.")
        return 1

    try:
        engine = load.get_engine(db_url)
        load.ensure_schema(engine, config.SCHEMA)
        schema.ensure_all_asset_tables(engine, config.SCHEMA, layers=layers_to_run)
    except Exception as exc:
        logger.error("Falha ao conectar ao banco de dados: %s", exc)
        return 1

    results: list[LayerResult] = []
    for layer_name in layers_to_run:
        result = process_layer(
            str(gdb_path),
            layer_name=layer_name,
            engine=engine,
            dist_name=args.distribuidora,
            regiao=args.regiao,
        )
        results.append(result)

    print_summary(results)

    return 0 if all(r.status == "OK" for r in results) else 1


if __name__ == "__main__":
    sys.exit(main())
