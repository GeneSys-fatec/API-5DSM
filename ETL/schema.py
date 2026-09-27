from __future__ import annotations

import hashlib
import logging
import re
from dataclasses import dataclass

import sqlalchemy as sa
from sqlalchemy import text

logger = logging.getLogger(__name__)

SRID = 4326

_PARTITION_SUFFIX_HASH_LENGTH = 8
_POSTGRES_IDENTIFIER_MAX_BYTES = 63
_NON_SLUG_CHARS_RE = re.compile(r"[^a-z0-9_]+")


@dataclass(frozen=True)
class AssetTableSpec:
    layer: str
    table_name: str
    geometry_type: str
    allowed_subtypes: tuple[str, ...] | None


ASSET_TABLE_SPECS: dict[str, AssetTableSpec] = {
    "POSTE": AssetTableSpec("POSTE", "poste", "Point", None),
    "SUB":   AssetTableSpec("SUB",   "sub",   "Geometry",
                             ("ST_Point", "ST_Polygon", "ST_MultiPolygon")),
    "UCBT":  AssetTableSpec("UCBT",  "ucbt", "Point", None),
    "UCMT":  AssetTableSpec("UCMT",  "ucmt", "Point", None),
    "SSDBT": AssetTableSpec("SSDBT", "ssdbt", "Geometry", None),
    "SSDMT": AssetTableSpec("SSDMT", "ssdmt", "Geometry", None),
    "SSDAT": AssetTableSpec("SSDAT", "ssdat", "Geometry", None),
}

FIXED_COLUMNS: tuple[str, ...] = (
    "tipo_ativo", "distribuidora", "regiao", "asset_key", "geometry",
)


def get_spec(layer_name: str) -> AssetTableSpec:
    try:
        return ASSET_TABLE_SPECS[layer_name]
    except KeyError:
        valid_layers = ", ".join(sorted(ASSET_TABLE_SPECS))
        raise KeyError(
            f"Layer {layer_name!r} não configurada em ASSET_TABLE_SPECS. "
            f"Layers válidas: {valid_layers}."
        ) from None


def _slugify(value: str) -> str:
    lowered = value.strip().lower()
    return _NON_SLUG_CHARS_RE.sub("_", lowered).strip("_")


def partition_suffix(distribuidora: str, regiao: str) -> str:
    # Determinístico (mesma entrada -> mesmo sufixo) e com hash sha1 curto
    # para evitar colisão/limite de 63 bytes de identificador do Postgres.
    slug_distribuidora = _slugify(distribuidora)
    slug_regiao = _slugify(regiao)

    digest = hashlib.sha1(f"{distribuidora}|{regiao}".encode("utf-8")).hexdigest()
    short_hash = digest[:_PARTITION_SUFFIX_HASH_LENGTH]

    slug_part = "_".join(part for part in (slug_distribuidora, slug_regiao) if part)
    suffix = f"{slug_part}_{short_hash}" if slug_part else short_hash

    max_suffix_bytes = _POSTGRES_IDENTIFIER_MAX_BYTES
    encoded_suffix = suffix.encode("utf-8")
    if len(encoded_suffix) > max_suffix_bytes:
        hash_with_separator = f"_{short_hash}".encode("utf-8")
        max_slug_bytes = max_suffix_bytes - len(hash_with_separator)
        truncated_slug = slug_part.encode("utf-8")[:max_slug_bytes].decode("utf-8", "ignore")
        truncated_slug = truncated_slug.rstrip("_")
        suffix = f"{truncated_slug}_{short_hash}" if truncated_slug else short_hash

    return suffix


def is_partitioned(engine: sa.Engine, pg_schema: str, table_name: str) -> bool:
    query = text(
        "SELECT 1 "
        "FROM pg_catalog.pg_class c "
        "JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace "
        "JOIN pg_catalog.pg_partitioned_table p ON p.partrelid = c.oid "
        "WHERE n.nspname = :pg_schema AND c.relname = :table_name"
    )
    with engine.connect() as conn:
        row = conn.execute(query, {"pg_schema": pg_schema, "table_name": table_name}).fetchone()

    return row is not None


def ddl_for_layer(layer_name: str, pg_schema: str) -> list[str]:
    # partition_key e coluna fisica normal (nao expressao, nao GENERATED):
    # e a unica forma do Postgres aceitar tambem um indice unico/PK cobrindo
    # a tabela particionada (ver decisao a2 do design.md). E preenchida pelo
    # Carregador_em_Lote (load.py::upsert_layer), nunca pelo Postgres.
    spec = get_spec(layer_name)
    table = spec.table_name
    qualified_table = f"{pg_schema}.{table}"

    if spec.allowed_subtypes:
        subtypes = ", ".join(f"'{subtype}'" for subtype in spec.allowed_subtypes)
        geometry_column = (
            f"    geometry       GEOMETRY({spec.geometry_type}, {SRID}) NOT NULL,\n"
            f"    CONSTRAINT chk_{table}_geometry_subtype CHECK (\n"
            f"        ST_GeometryType(geometry) IN ({subtypes})\n"
            f"    )"
        )
    else:
        geometry_column = f"    geometry       GEOMETRY({spec.geometry_type}, {SRID}) NOT NULL"

    create_table = (
        f"CREATE TABLE IF NOT EXISTS {qualified_table} (\n"
        f"    id             BIGSERIAL NOT NULL,\n"
        f"    tipo_ativo     TEXT NOT NULL,\n"
        f"    distribuidora  TEXT NOT NULL,\n"
        f"    regiao         TEXT NOT NULL,\n"
        f"    asset_key      TEXT NOT NULL,\n"
        f"    partition_key  TEXT NOT NULL,\n"
        f"{geometry_column}\n"
        f") PARTITION BY LIST (partition_key);"
    )

    create_unique_index = (
        f"CREATE UNIQUE INDEX IF NOT EXISTS uq_{table}_asset_key "
        f"ON {qualified_table} (partition_key, asset_key);"
    )

    create_gist_index = (
        f"CREATE INDEX IF NOT EXISTS idx_{table}_geometry "
        f"ON {qualified_table} USING GIST (geometry);"
    )

    return [create_table, create_unique_index, create_gist_index]


def ensure_partition(
    engine: sa.Engine,
    layer_name: str,
    pg_schema: str,
    distribuidora: str,
    regiao: str,
) -> None:
    if distribuidora is None or not distribuidora.strip():
        raise ValueError(
            f"distribuidora inválida ({distribuidora!r}): não pode ser None, vazia ou "
            "composta só de espaços em branco — não é possível criar Partição_de_Ativo "
            "com Chave_de_Particionamento indefinida."
        )
    if regiao is None or not regiao.strip():
        raise ValueError(
            f"regiao inválida ({regiao!r}): não pode ser None, vazia ou composta só de "
            "espaços em branco — não é possível criar Partição_de_Ativo com "
            "Chave_de_Particionamento indefinida."
        )

    spec = get_spec(layer_name)
    table = spec.table_name
    qualified_table = f"{pg_schema}.{table}"
    partition_name = f"{table}_{partition_suffix(distribuidora, regiao)}"
    qualified_partition = f"{pg_schema}.{partition_name}"
    partition_key = f"{distribuidora}::{regiao}"

    create_partition = text(
        f"CREATE TABLE IF NOT EXISTS {qualified_partition} "
        f"PARTITION OF {qualified_table} "
        f"FOR VALUES IN (:partition_key)"
    )

    logger.info(
        "Garantindo partição '%s' para (distribuidora=%r, regiao=%r) …",
        qualified_partition, distribuidora, regiao,
    )
    try:
        with engine.begin() as conn:
            conn.execute(create_partition, {"partition_key": partition_key})
    except Exception as exc:
        raise RuntimeError(
            f"Falha ao criar Partição_de_Ativo em '{pg_schema}.{table}' para "
            f"(distribuidora={distribuidora!r}, regiao={regiao!r}): {exc}"
        ) from exc

    logger.info("Partição '%s' garantida.", qualified_partition)


def _table_exists(engine: sa.Engine, pg_schema: str, table_name: str) -> bool:
    query = text(
        "SELECT 1 FROM information_schema.tables "
        "WHERE table_schema = :pg_schema AND table_name = :table_name"
    )
    with engine.connect() as conn:
        row = conn.execute(query, {"pg_schema": pg_schema, "table_name": table_name}).fetchone()

    return row is not None


def _create_partitioned_table(conn: sa.Connection, layer_name: str, pg_schema: str) -> None:
    spec = get_spec(layer_name)
    statements = ddl_for_layer(layer_name, pg_schema)

    for statement in statements:
        logger.debug("Executando DDL para '%s.%s':\n%s", pg_schema, spec.table_name, statement)
        conn.execute(text(statement))
        logger.debug("DDL executado com sucesso para '%s.%s'.", pg_schema, spec.table_name)

    if spec.geometry_type == "Geometry":
        conn.execute(text(
            f"ALTER TABLE {pg_schema}.{spec.table_name} "
            "ALTER COLUMN geometry TYPE GEOMETRY USING geometry"
        ))


def _ensure_partition_inline(
    conn: sa.Connection,
    layer_name: str,
    pg_schema: str,
    distribuidora: str,
    regiao: str,
) -> None:
    # Mesma lógica de ensure_partition, mas na conexão/transação já aberta
    # pelo chamador (migrate_to_partitioned), preservando a atomicidade.
    spec = get_spec(layer_name)
    table = spec.table_name
    qualified_table = f"{pg_schema}.{table}"
    partition_name = f"{table}_{partition_suffix(distribuidora, regiao)}"
    qualified_partition = f"{pg_schema}.{partition_name}"
    partition_key = f"{distribuidora}::{regiao}"

    create_partition = text(
        f"CREATE TABLE IF NOT EXISTS {qualified_partition} "
        f"PARTITION OF {qualified_table} "
        f"FOR VALUES IN (:partition_key)"
    )
    conn.execute(create_partition, {"partition_key": partition_key})


def migrate_to_partitioned(engine: sa.Engine, layer_name: str, pg_schema: str) -> None:
    spec = get_spec(layer_name)
    table = spec.table_name
    qualified_identifier = f"{pg_schema}.{table}"

    invalid_count_query = text(
        f"SELECT COUNT(*) FROM {pg_schema}.{table} "
        "WHERE distribuidora IS NULL OR TRIM(distribuidora) = '' "
        "OR regiao IS NULL OR TRIM(regiao) = ''"
    )
    with engine.connect() as conn:
        invalid_count = conn.execute(invalid_count_query).scalar_one()

    if invalid_count > 0:
        raise ValueError(
            f"Migração de '{qualified_identifier}' abortada: {invalid_count} Ativo(s) "
            "com distribuidora e/ou regiao nula, vazia ou composta só de espaços em "
            "branco. Nenhuma alteração foi aplicada. Corrija os dados na tabela original "
            "antes de tentar migrar novamente."
        )

    old_table = f"{table}_old"
    qualified_old_table = f"{pg_schema}.{old_table}"

    logger.info("Iniciando migração de '%s' para tabela particionada …", qualified_identifier)
    try:
        with engine.begin() as conn:
            conn.execute(text(f"ALTER TABLE {pg_schema}.{table} RENAME TO {old_table}"))

            _create_partitioned_table(conn, layer_name, pg_schema)

            distinct_keys = conn.execute(
                text(f"SELECT DISTINCT distribuidora, regiao FROM {qualified_old_table}")
            ).fetchall()
            for distribuidora, regiao in distinct_keys:
                _ensure_partition_inline(conn, layer_name, pg_schema, distribuidora, regiao)

            conn.execute(text(
                f"INSERT INTO {pg_schema}.{table} "
                "(id, tipo_ativo, distribuidora, regiao, asset_key, partition_key, geometry) "
                "SELECT id, tipo_ativo, distribuidora, regiao, asset_key, "
                "distribuidora || '::' || regiao, geometry "
                f"FROM {qualified_old_table}"
            ))

            old_count = conn.execute(text(f"SELECT COUNT(*) FROM {qualified_old_table}")).scalar_one()
            new_count = conn.execute(text(f"SELECT COUNT(*) FROM {pg_schema}.{table}")).scalar_one()
            if new_count != old_count:
                raise RuntimeError(
                    f"Migração de '{qualified_identifier}' abortada: a tabela nova ficou "
                    f"com {new_count} linha(s), mas a tabela original tinha {old_count}. "
                    "Rollback será acionado."
                )

            conn.execute(text(f"DROP TABLE {qualified_old_table}"))
    except Exception as exc:
        raise RuntimeError(
            f"Falha ao migrar '{qualified_identifier}' para tabela particionada: {exc}"
        ) from exc

    logger.info("Migração de '%s' para tabela particionada concluída.", qualified_identifier)


def ensure_asset_table(engine: sa.Engine, layer_name: str, pg_schema: str) -> None:
    spec = get_spec(layer_name)
    table = spec.table_name

    if not _table_exists(engine, pg_schema, table):
        logger.info(
            "Tabela '%s.%s' (layer '%s') não existe — criando já particionada …",
            pg_schema, table, layer_name,
        )
        with engine.begin() as conn:
            _create_partitioned_table(conn, layer_name, pg_schema)
        logger.info("Tabela '%s.%s' criada.", pg_schema, table)
        return

    if is_partitioned(engine, pg_schema, table):
        logger.info(
            "Tabela '%s.%s' (layer '%s') já particionada — nenhuma ação necessária.",
            pg_schema, table, layer_name,
        )
        return

    logger.info(
        "Tabela '%s.%s' (layer '%s') existe e não é particionada — migrando …",
        pg_schema, table, layer_name,
    )
    migrate_to_partitioned(engine, layer_name, pg_schema)
    logger.info("Tabela '%s.%s' migrada e garantida.", pg_schema, table)


def ensure_all_asset_tables(
    engine: sa.Engine,
    pg_schema: str,
    layers: list[str] | None = None,
) -> None:
    layers_to_apply = layers if layers is not None else list(ASSET_TABLE_SPECS)

    logger.info("Garantindo tabelas de ativo para as layers: %s", ", ".join(layers_to_apply))
    for layer_name in layers_to_apply:
        ensure_asset_table(engine, layer_name, pg_schema)