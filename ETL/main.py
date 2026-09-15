"""
main.py — Orquestrador do pipeline ETL da BDGD.

Uso
---
    python main.py <caminho.gdb> <NOME_DISTRIBUIDORA>

Exemplos
--------
    python main.py /dados/CEMIG_2023.gdb CEMIG
    python main.py C:/bdgd/ENEL_SP_2022.gdb ENEL_SP

Critério de aceite (passos do SYS-14)
--------------------------------------
1. Loga as layers encontradas no GDB e compara com config.LAYERS.
2. Para cada layer, resolve o campo chave (COD_ID ou fallback FID).
3. Trata CRS ausente com aviso — não silencia.
4. Faz upsert no PostGIS com índice GiST.
5. Segunda execução com o mesmo arquivo não duplica dados.
6. Falha numa layer (ex: campo chave ausente) não impede as demais.
7. Ao final, imprime tabela de resumo com status por layer.
"""
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

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("bdgd_etl.main")


# ---------------------------------------------------------------------------
# Estrutura de resultado por layer
# ---------------------------------------------------------------------------

@dataclass
class LayerResult:
    layer: str
    rows: int = 0
    elapsed_s: float = 0.0
    status: str = "OK"
    error: Optional[str] = None


# ---------------------------------------------------------------------------
# Resolução do campo chave com fallback
# ---------------------------------------------------------------------------

def resolve_key_col(gdf, layer_name: str) -> str:
    """Retorna o campo chave efetivo para a layer.

    Tenta, em ordem:
    1. config.KEY_COLUMN_BY_LAYER[layer_name]
    2. config.KEY_COLUMN_FALLBACK ("FID")

    Raises
    ------
    KeyError
        Se nenhuma das duas opções estiver presente no GeoDataFrame.
    """
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


# ---------------------------------------------------------------------------
# Processamento de uma layer (isolado para captura de exceção)
# ---------------------------------------------------------------------------

def process_layer(
    gdb_path: str,
    layer_name: str,
    engine,
    dist_name: str,
) -> LayerResult:
    """Executa Extract → Transform → Load para uma layer.

    Qualquer exceção é capturada aqui: a layer recebe status ERRO e o
    pipeline continua para as demais layers.
    """
    result = LayerResult(layer=layer_name)
    t0 = time.perf_counter()

    try:
        # ---- Extract -------------------------------------------------------
        logger.info("=== [%s] Extraindo …", layer_name)
        gdf = extract.read_layer(gdb_path, layer_name)

        # ---- Resolve campo chave -------------------------------------------
        key_col = resolve_key_col(gdf, layer_name)
        logger.info("[%s] Campo chave: '%s'", layer_name, key_col)

        # ---- Transform -------------------------------------------------------
        logger.info("[%s] Transformando …", layer_name)
        gdf = transform.prepare_layer(
            gdf,
            layer_name=layer_name,
            key_col=key_col,
            target_crs=config.TARGET_CRS,
            source_crs_fallback=config.SOURCE_CRS_FALLBACK,
        )

        # Acrescenta nome da distribuidora como coluna de rastreabilidade
        gdf["distribuidora"] = dist_name

        # ---- Load -----------------------------------------------------------
        table_name = layer_name.lower()
        logger.info("[%s] Carregando em '%s.%s' …", layer_name, config.SCHEMA, table_name)
        rows = load.upsert_layer(
            gdf,
            table_name=table_name,
            key_col=key_col,
            engine=engine,
            schema=config.SCHEMA,
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


# ---------------------------------------------------------------------------
# Tabela de resumo final
# ---------------------------------------------------------------------------

def print_summary(results: list[LayerResult]) -> None:
    """Imprime tabela de resumo com status por layer."""
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


# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Pipeline ETL para importar dados da BDGD no PostGIS.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
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

    # Ajusta log level via argumento
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

    # -- Passo 1: listar layers disponíveis no GDB --------------------------
    logger.info("Listando layers disponíveis no GDB …")
    try:
        available_layers = extract.list_available_layers(str(gdb_path))
    except RuntimeError as exc:
        logger.error("Não foi possível abrir o GDB: %s", exc)
        return 1

    # Filtra apenas layers que existem no GDB
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

    # -- Conecta ao banco e garante schema ----------------------------------
    try:
        engine = load.get_engine(db_url)
        load.ensure_schema(engine, config.SCHEMA)
    except Exception as exc:
        logger.error("Falha ao conectar ao banco de dados: %s", exc)
        return 1

    # -- Processa cada layer individualmente ---------------------------------
    results: list[LayerResult] = []
    for layer_name in layers_to_run:
        result = process_layer(
            str(gdb_path),
            layer_name=layer_name,
            engine=engine,
            dist_name=args.distribuidora,
        )
        results.append(result)

    # -- Resumo final --------------------------------------------------------
    print_summary(results)

    # Retorna código de saída 0 se todas OK, 1 se alguma falhou
    return 0 if all(r.status == "OK" for r in results) else 1


if __name__ == "__main__":
    sys.exit(main())
