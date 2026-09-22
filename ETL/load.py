from __future__ import annotations

import logging
import re

import geopandas as gpd
import pandas as pd
import sqlalchemy as sa
from sqlalchemy import text

import schema

logger = logging.getLogger(__name__)

BATCH_SIZE = 5_000


def get_engine(db_url: str) -> sa.Engine:
    """Cria e retorna uma engine SQLAlchemy para o banco de dados.

    Parameters
    ----------
    db_url:
        Connection string PostgreSQL, ex.:
        "postgresql://postgres:postgres@localhost:5432/bdgd"

    Returns
    -------
    sqlalchemy.Engine
    """
    try:
        engine = sa.create_engine(
            db_url,
            pool_pre_ping=True,
            connect_args={"client_encoding": "utf8"},
        )
        # Valida a conexão imediatamente
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        logger.info("Conexão ao banco estabelecida: %s", _mask_password(db_url))
        return engine
    except Exception as exc:
        # Trata erros de codificação quando o Postgres no Windows responde mensagens de erro em CP1252 (ex: "autenticação falhou")
        if isinstance(exc, UnicodeDecodeError) or "codec can't decode" in str(exc):
            raw_bytes = getattr(exc, "object", None)
            if isinstance(raw_bytes, bytes):
                decoded_msg = raw_bytes.decode("latin1", errors="replace").strip()
                raise RuntimeError(f"Erro de conexão com PostgreSQL: {decoded_msg}") from exc
        raise



def _mask_password(url: str) -> str:
    return re.sub(r"(:)[^:@]+(@)", r"\1***\2", url)


def ensure_schema(engine: sa.Engine, schema: str) -> None:
    with engine.begin() as conn:
        conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {schema}"))
    logger.info("Schema '%s' garantido.", schema)


def _is_valid_partition_key_value(value: object) -> bool:
    """Define, em um único lugar, o que conta como valor inválido de
    Chave_de_Particionamento: `None`/`NaN`, string vazia ou composta só de
    espaços em branco. Reutilizada por `_valid_partition_key_mask` e por
    `_log_rejected_rows` para não duplicar a definição de "inválido".
    """
    if value is None or (not isinstance(value, str) and pd.isna(value)):
        return False
    if not isinstance(value, str):
        return True
    return value.strip() != ""


def _valid_partition_key_mask(gdf: pd.DataFrame) -> pd.Series:
    """Marca como inválida qualquer linha cuja `distribuidora` e/ou `regiao`
    seja `None`, string vazia, ou composta só de espaços em branco.

    Função pura: não modifica `gdf`. Não faz trim de valores válidos com
    espaços nas bordas (ex. `" CEMIG "` permanece válido) — decisão de
    design explícita, pois a normalização de Chave_de_Particionamento não é
    responsabilidade desta função.

    Parameters
    ----------
    gdf:
        GeoDataFrame ou DataFrame contendo, no mínimo, as colunas
        `distribuidora` e `regiao`.

    Returns
    -------
    pandas.Series (bool)
        Máscara com o mesmo índice de `gdf`: `True` para linhas válidas
        (ambas as colunas presentes e não nulas/vazias/em branco), `False`
        para linhas inválidas.
    """
    distribuidora_valid = gdf["distribuidora"].apply(_is_valid_partition_key_value)
    regiao_valid = gdf["regiao"].apply(_is_valid_partition_key_value)
    return distribuidora_valid & regiao_valid


def _log_rejected_rows(layer_name: str, invalid_rows: pd.DataFrame) -> None:
    """Loga, via `logger.error`, cada linha rejeitada por ter
    `distribuidora` e/ou `regiao` nula, vazia ou em branco.

    Reutiliza `_is_valid_partition_key_value` (a mesma lógica usada por
    `_valid_partition_key_mask`) para identificar exatamente qual(is)
    coluna(s) está(ão) inválida(s) em cada linha, evitando duplicar a
    definição de "inválido". Função apenas de logging: não levanta exceção
    nem modifica `invalid_rows` — o descarte das linhas é responsabilidade
    de quem chama.

    Parameters
    ----------
    layer_name:
        Nome da Layer sendo carregada, incluído em cada mensagem de log
        para identificar a origem das linhas rejeitadas.
    invalid_rows:
        DataFrame contendo apenas as linhas já identificadas como inválidas
        (deve conter, no mínimo, as colunas `distribuidora` e `regiao`).
    """
    for row_index, row in invalid_rows.iterrows():
        invalid_columns = [
            column
            for column in ("distribuidora", "regiao")
            if not _is_valid_partition_key_value(row[column])
        ]
        logger.error(
            "Linha rejeitada em '%s' (índice %s): coluna(s) inválida(s) "
            "(nula, vazia ou em branco): %s.",
            layer_name,
            row_index,
            ", ".join(invalid_columns),
        )


def _check_cross_partition_conflict(
    conn: sa.Connection,
    pg_schema: str,
    table_name: str,
    partition_key: str,
    asset_keys: list[str],
) -> None:
    """Verifica se algum `asset_key` do grupo atual já existe em outra
    Partição_de_Ativo (Chave_de_Particionamento diferente da do grupo).

    Executa contra a tabela-mãe (o Postgres varre automaticamente todas as
    partições). Se encontrar qualquer linha conflitante, levanta `ValueError`
    identificando o(s) `asset_key`(s) em conflito e as duas
    Chaves_de_Particionamento envolvidas — sem alterar o registro já
    existente na outra partição, e sem executar o `INSERT` do grupo atual
    (Requisitos 2.1, 2.3).

    Parameters
    ----------
    conn:
        Conexão/transação já aberta (a checagem participa da mesma
        transação do INSERT do grupo, para consistência).
    pg_schema, table_name:
        Schema e tabela-mãe contra os quais a checagem é executada.
    partition_key:
        Chave_de_Particionamento do grupo atual (f"{distribuidora}::{regiao}").
    asset_keys:
        Lista de `asset_key` únicos presentes no grupo atual.
    """
    if not asset_keys:
        return

    query = text(
        f"SELECT asset_key, distribuidora, regiao "
        f"FROM {pg_schema}.{table_name} "
        f"WHERE asset_key = ANY(:asset_keys) AND partition_key <> :partition_key"
    )
    conflicts = conn.execute(
        query, {"asset_keys": list(asset_keys), "partition_key": partition_key}
    ).fetchall()

    if conflicts:
        conflict_details = "; ".join(
            f"asset_key={row.asset_key!r} já existe em "
            f"partition_key={row.distribuidora}::{row.regiao}"
            for row in conflicts
        )
        raise ValueError(
            f"Conflito de asset_key entre partições em '{pg_schema}.{table_name}': "
            f"tentativa de inserir/atualizar na partição '{partition_key}', mas "
            f"{conflict_details}. Uma asset_key não pode existir em mais de uma "
            f"Chave_de_Particionamento — INSERT deste grupo abortado, registro(s) "
            f"existente(s) na outra partição permanece(m) inalterado(s)."
        )


def upsert_layer(
    gdf: gpd.GeoDataFrame,
    layer_name: str,
    key_col: str,
    engine: sa.Engine,
    pg_schema: str,
) -> int:
    if gdf.empty:
        logger.warning("GeoDataFrame vazio para '%s' — nada a carregar.", layer_name)
        return 0

    spec = schema.get_spec(layer_name)
    schema.ensure_asset_table(engine, layer_name, pg_schema)
    table_name = spec.table_name

    # Projeta o GeoDataFrame para exatamente as colunas normalizadas fixas,
    # descartando quaisquer colunas extras vindas de transform.py
    gdf = pd.DataFrame(gdf[list(schema.FIXED_COLUMNS)].copy())

    # Valida distribuidora/regiao linha a linha (Requisito 5.2): descarta e
    # loga as linhas inválidas, sem abortar o restante do lote.
    valid_mask = _valid_partition_key_mask(gdf)
    invalid_rows = gdf[~valid_mask]
    if not invalid_rows.empty:
        _log_rejected_rows(layer_name, invalid_rows)
    gdf = gdf[valid_mask]

    if gdf.empty:
        logger.warning(
            "Nenhuma linha válida para '%s' após validação de distribuidora/regiao "
            "— nada a carregar.",
            layer_name,
        )
        return 0

    # coluna física comum, preenchida aqui pelo código Python — não é
    # GENERATED ALWAYS/computada pelo Postgres (ver decisão (a2) no design.md).
    # Calculada só sobre as linhas já válidas (não há sentido em calcular
    # partition_key de linhas que serão descartadas).
    gdf["partition_key"] = gdf["distribuidora"] + "::" + gdf["regiao"]

    srid = 4326
    gdf["geometry"] = gdf["geometry"].apply(
        lambda geom: f"SRID={srid};{geom.wkt}" if geom is not None else None
    )

    total_processed = 0

    sample_row = gdf.iloc[0].to_dict()
    col_names = list(sample_row.keys())
    col_list = ", ".join(col_names)
    col_list_cast = ", ".join(
        "CAST(:geometry AS geometry)" if c == "geometry" else f":{c}"
        for c in col_names
    )
    update_set = ", ".join(
        f"{c} = EXCLUDED.{c}"
        for c in col_names
        if c != "asset_key"
    )
    sql = text(f"""
        INSERT INTO {pg_schema}.{table_name} ({col_list})
        VALUES ({col_list_cast})
        ON CONFLICT (partition_key, asset_key)
        DO UPDATE SET {update_set}
    """)

    # Agrupa as linhas válidas por (distribuidora, regiao), ordem
    # determinística (Requisito 1.2, 4.3).
    for (distribuidora, regiao), group in gdf.groupby(
        ["distribuidora", "regiao"], sort=True
    ):
        schema.ensure_partition(engine, layer_name, pg_schema, distribuidora, regiao)

        partition_key = f"{distribuidora}::{regiao}"
        asset_keys = group["asset_key"].unique().tolist()

        for start in range(0, len(group), BATCH_SIZE):
            batch = group.iloc[start : start + BATCH_SIZE]
            rows = batch.to_dict(orient="records")

            with engine.begin() as conn:
                _check_cross_partition_conflict(
                    conn, pg_schema, table_name, partition_key, asset_keys
                )
                conn.execute(sql, rows)

            total_processed += len(batch)
            logger.info(
                "Batch %d–%d do grupo (%r, %r) de '%s' carregado.",
                start + 1, start + len(batch), distribuidora, regiao, table_name,
            )

    logger.info(
        "upsert_layer: %d feições processadas em '%s.%s'.",
        total_processed, pg_schema, table_name,
    )
    return total_processed
