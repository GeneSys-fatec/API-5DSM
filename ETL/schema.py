"""
schema.py — Schema_Manager: definição e aplicação idempotente do DDL das
Tabelas_de_Ativo da BDGD no PostGIS.

Responsabilidade única: estrutura das tabelas (colunas, tipos, constraints,
índices). NÃO faz upsert de dados — isso é responsabilidade de load.py.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass

import sqlalchemy as sa
from sqlalchemy import text

logger = logging.getLogger(__name__)

SRID = 4326


@dataclass(frozen=True)
class AssetTableSpec:
    layer: str                       # nome da Layer, ex. "SUB"
    table_name: str                  # nome da tabela, ex. "sub"
    geometry_type: str               # tipo PostGIS: "Point" | "Geometry"
    allowed_subtypes: tuple[str, ...] | None
    # subtipos permitidos via CHECK quando geometry_type == "Geometry";
    # None quando o tipo já é restrito na própria coluna (ex. "Point")


# Fonte única de verdade: uma entrada por Layer em escopo
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

# Colunas normalizadas fixas, na ordem em que aparecem no DDL.
# Reexportado para load.py usar na projeção de colunas antes do INSERT.
FIXED_COLUMNS: tuple[str, ...] = (
    "tipo_ativo", "distribuidora", "regiao", "asset_key", "geometry",
)


def get_spec(layer_name: str) -> AssetTableSpec:
    """Retorna o AssetTableSpec da layer, ou levanta KeyError se não configurada."""
    try:
        return ASSET_TABLE_SPECS[layer_name]
    except KeyError:
        valid_layers = ", ".join(sorted(ASSET_TABLE_SPECS))
        raise KeyError(
            f"Layer {layer_name!r} não configurada em ASSET_TABLE_SPECS. "
            f"Layers válidas: {valid_layers}."
        ) from None


def ddl_for_layer(layer_name: str, pg_schema: str) -> list[str]:
    """Monta as instruções DDL (CREATE TABLE + índices) para a layer.

    Retorna uma lista de statements SQL (não concatenados), para que cada um
    possa ser executado e logado individualmente.
    Não executa nada — apenas gera o SQL. Função pura, fácil de testar.
    """
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
        f"    id             BIGSERIAL PRIMARY KEY,\n"
        f"    tipo_ativo     TEXT NOT NULL,\n"
        f"    distribuidora  TEXT NOT NULL,\n"
        f"    regiao         TEXT NOT NULL,\n"
        f"    asset_key      TEXT NOT NULL,\n"
        f"{geometry_column}\n"
        f");"
    )

    create_unique_index = (
        f"CREATE UNIQUE INDEX IF NOT EXISTS uq_{table}_asset_key "
        f"ON {qualified_table} (asset_key);"
    )

    create_gist_index = (
        f"CREATE INDEX IF NOT EXISTS idx_{table}_geometry "
        f"ON {qualified_table} USING GIST (geometry);"
    )

    return [create_table, create_unique_index, create_gist_index]


def ensure_asset_table(engine: sa.Engine, layer_name: str, pg_schema: str) -> None:
    """Aplica o DDL da layer no banco. Idempotente:
    - CREATE TABLE IF NOT EXISTS
    - CREATE UNIQUE INDEX IF NOT EXISTS (asset_key)
    - CREATE INDEX IF NOT EXISTS ... USING GIST (geometry)
    Se a tabela já existir, os comandos são no-op — não recria nem altera
    estrutura existente (Requisitos 1.3, 6.3, 6.4).
    """
    spec = get_spec(layer_name)
    statements = ddl_for_layer(layer_name, pg_schema)

    logger.info(
        "Garantindo tabela '%s.%s' (layer '%s') …",
        pg_schema, spec.table_name, layer_name,
    )
    with engine.begin() as conn:
        for statement in statements:
            logger.debug("Executando DDL para '%s.%s':\n%s", pg_schema, spec.table_name, statement)
            conn.execute(text(statement))
            logger.debug("DDL executado com sucesso para '%s.%s'.", pg_schema, spec.table_name)

        if spec.geometry_type == "Geometry":
            conn.execute(text(
                f"ALTER TABLE {pg_schema}.{spec.table_name} "
                "ALTER COLUMN geometry TYPE GEOMETRY USING geometry"
            ))

    logger.info("Tabela '%s.%s' garantida.", pg_schema, spec.table_name)


def ensure_all_asset_tables(
    engine: sa.Engine,
    pg_schema: str,
    layers: list[str] | None = None,
) -> None:
    """Chama ensure_asset_table para cada layer em `layers` (default:
    todas em ASSET_TABLE_SPECS). Usado por main.py antes do loop de carga.
    """
    layers_to_apply = layers if layers is not None else list(ASSET_TABLE_SPECS)

    logger.info("Garantindo tabelas de ativo para as layers: %s", ", ".join(layers_to_apply))
    for layer_name in layers_to_apply:
        ensure_asset_table(engine, layer_name, pg_schema)
