"""Property-based tests (Hypothesis) para a migração de Tabelas_de_Ativo
legadas (não particionadas) para a estrutura particionada nativa
(spec `carga-lote-particionada`, SYS-19).
"""

from __future__ import annotations

import sys
from pathlib import Path

import geopandas as gpd
import pytest
import sqlalchemy as sa
from hypothesis import HealthCheck, given, settings
from hypothesis import strategies as st
from shapely.geometry import Point

_ETL_DIR = Path(__file__).resolve().parent.parent
if str(_ETL_DIR) not in sys.path:
    sys.path.insert(0, str(_ETL_DIR))

import load  # noqa: E402
import schema  # noqa: E402
import transform  # noqa: E402

# Alfabeto restrito a caracteres "razoáveis" de nome de distribuidora/região
# (letras ASCII, dígitos, espaço, hífen e underscore) — mesmo alfabeto usado
# em test_properties_partitioning.py, para consistência entre os testes de
# propriedade desta feature.
_KEY_PART_ALPHABET = st.characters(
    whitelist_categories=("Lu", "Ll", "Nd"),
    whitelist_characters=" -_",
)


def _non_blank_key_text() -> st.SearchStrategy[str]:
    """Strategy de texto não-vazio (após strip) usada para componentes de
    Chave_de_Particionamento (`distribuidora`/`regiao`) nos testes de
    propriedade deste módulo.
    """
    return st.text(alphabet=_KEY_PART_ALPHABET, min_size=1, max_size=20).map(
        lambda s: s.strip()
    ).filter(lambda s: s != "")


_key_part_text = _non_blank_key_text()
_partition_key_pair = st.tuples(_key_part_text, _key_part_text)

_cod_id_strategy = st.text(
    alphabet=st.characters(whitelist_categories=("Lu", "Ll", "Nd")),
    min_size=1,
    max_size=10,
).filter(lambda s: s.strip() != "")

# DDL da Tabela_de_Ativo legada (não particionada), conforme definido pela
# spec bdgd-schema-tabelas antes da introdução do particionamento nesta
# feature: id BIGSERIAL PRIMARY KEY, colunas normalizadas fixas, índice
# único em (asset_key) isolado, SEM partition_key, SEM PARTITION BY — a
# estrutura exata que schema.py::migrate_to_partitioned espera encontrar ao
# migrar uma tabela existente (ver schema.py::_table_exists/is_partitioned e
# TestMigrateToPartitioned em test_schema.py, mesma convenção de LEGACY_DDL).
_LEGACY_DDL = (
    "CREATE TABLE {qualified_table} ("
    "id BIGSERIAL PRIMARY KEY, "
    "tipo_ativo TEXT NOT NULL, "
    "distribuidora TEXT NOT NULL, "
    "regiao TEXT NOT NULL, "
    "asset_key TEXT NOT NULL UNIQUE, "
    "geometry GEOMETRY(Point,4326) NOT NULL"
    ")"
)


def _create_legacy_table(engine: sa.Engine, qualified_table: str) -> None:
    """Cria a tabela legada (não particionada) via DDL antigo, diretamente
    por SQL — não via `schema.ddl_for_layer` (que já gera a estrutura
    particionada nova) nem via `schema.ensure_asset_table`.
    """
    with engine.begin() as conn:
        conn.execute(sa.text(_LEGACY_DDL.format(qualified_table=qualified_table)))


def _insert_legacy_row(
    engine: sa.Engine,
    qualified_table: str,
    tipo_ativo: str,
    distribuidora: str,
    regiao: str,
    asset_key: str,
    lon: float,
    lat: float,
) -> None:
    """Popula a tabela legada diretamente via SQL — não via
    `load.upsert_layer`, que já espera a estrutura particionada
    (coluna `partition_key`, índice único `(partition_key, asset_key)`).
    """
    insert_sql = sa.text(
        f"""
        INSERT INTO {qualified_table} (tipo_ativo, distribuidora, regiao, asset_key, geometry)
        VALUES (
            :tipo_ativo, :distribuidora, :regiao, :asset_key,
            ST_SetSRID(ST_MakePoint(:lon, :lat), {schema.SRID})
        )
        """
    )
    with engine.begin() as conn:
        conn.execute(
            insert_sql,
            {
                "tipo_ativo": tipo_ativo,
                "distribuidora": distribuidora,
                "regiao": regiao,
                "asset_key": asset_key,
                "lon": lon,
                "lat": lat,
            },
        )


def _fetch_all_rows(engine: sa.Engine, qualified_table: str) -> list[sa.Row]:
    """Lê todas as linhas de `qualified_table`, incluindo a geometria como
    texto (`ST_AsText`) para permitir comparação de valor direta (evita
    comparar bytes WKB, que podem diferir em representação mesmo para o
    mesmo ponto geográfico).
    """
    with engine.connect() as conn:
        return conn.execute(
            sa.text(
                f"SELECT asset_key, tipo_ativo, distribuidora, regiao, "
                f"ST_AsText(geometry) AS geom_text "
                f"FROM {qualified_table} ORDER BY asset_key"
            )
        ).fetchall()


# Gera de 1 a 6 Ativos, cada um com sua própria combinação de
# (distribuidora, regiao) — cobre tanto o caso de uma única
# Chave_de_Particionamento quanto múltiplas combinações distintas migrando
# para múltiplas Partições_de_Ativo.
_ativos_strategy = st.lists(
    st.tuples(_partition_key_pair, _cod_id_strategy),
    min_size=1,
    max_size=6,
)


class TestMigrationPreservesCountAndValuesProperty:
    """Feature: carga-lote-particionada, Property 6: Migração preserva
    contagem e valores de todos os Ativos.

    **Validates: Requirements 3.1**

    Gera um conjunto arbitrário de Ativos válidos (múltiplas combinações de
    distribuidora/regiao), popula uma tabela legada não particionada (DDL
    antigo), migra via `schema.migrate_to_partitioned`, e verifica que a
    contagem total e os valores de cada coluna (incluindo asset_key e
    geometry) são idênticos aos de antes da migração.
    """

    @settings(
        max_examples=100,
        deadline=None,
        suppress_health_check=[HealthCheck.function_scoped_fixture, HealthCheck.too_slow],
    )
    @given(ativos=_ativos_strategy)
    def test_migration_preserves_count_and_column_values(self, engine, pg_schema, ativos):
        layer_name = "POSTE"
        table_name = schema.ASSET_TABLE_SPECS[layer_name].table_name
        qualified_table = f"{pg_schema}.{table_name}"

        # `pg_schema` é um fixture por-teste (não por-exemplo do Hypothesis):
        # a tabela legada precisa ser recriada do zero em cada exemplo, já
        # que exemplos anteriores desta mesma execução já a migraram para a
        # estrutura particionada (schema.migrate_to_partitioned renomeia e
        # substitui a tabela-mãe) — sem isso, o segundo exemplo em diante
        # encontraria uma tabela já particionada, não a legada esperada por
        # este teste.
        with engine.begin() as conn:
            conn.execute(sa.text(f"DROP TABLE IF EXISTS {qualified_table} CASCADE"))
            conn.execute(sa.text(f"DROP TABLE IF EXISTS {qualified_table}_old CASCADE"))
        _create_legacy_table(engine, qualified_table)

        # Cada Ativo gerado recebe uma asset_key única dentro deste exemplo
        # (salt derivado da combinação de particionamento e da posição no
        # lote), para não colidir com asset_keys de outros exemplos
        # executados no mesmo schema compartilhado nem entre Ativos do
        # próprio exemplo.
        example_salt = abs(hash(tuple(ativos)))
        expected_rows: dict[str, tuple[str, str, str]] = {}
        for index, ((distribuidora, regiao), cod_id) in enumerate(ativos):
            asset_key = f"{layer_name}::{cod_id}_{example_salt}_{index}"
            lon = -46.0 + index * 0.01
            lat = -23.0 + index * 0.01
            _insert_legacy_row(
                engine, qualified_table, layer_name, distribuidora, regiao, asset_key, lon, lat
            )
            expected_rows[asset_key] = (
                distribuidora,
                regiao,
                f"POINT({lon} {lat})",
            )

        original_rows = _fetch_all_rows(engine, qualified_table)
        original_by_key = {row.asset_key: row for row in original_rows}
        assert len(original_by_key) == len(expected_rows), (
            "Falha de setup do teste: número de linhas inseridas na tabela legada "
            f"({len(original_by_key)}) não corresponde ao número de Ativos gerados "
            f"({len(expected_rows)})."
        )

        schema.migrate_to_partitioned(engine, layer_name, pg_schema)

        assert schema.is_partitioned(engine, pg_schema, table_name) is True, (
            "Tabela deveria estar particionada após migrate_to_partitioned."
        )

        migrated_rows = _fetch_all_rows(engine, qualified_table)
        migrated_by_key = {row.asset_key: row for row in migrated_rows}

        assert len(migrated_rows) == len(original_rows), (
            f"Contagem total diverge após a migração: original={len(original_rows)}, "
            f"migrada={len(migrated_rows)}."
        )
        assert set(migrated_by_key.keys()) == set(original_by_key.keys()), (
            "Conjunto de asset_key após a migração diverge do conjunto original: "
            f"faltando={set(original_by_key) - set(migrated_by_key)!r}, "
            f"extra={set(migrated_by_key) - set(original_by_key)!r}."
        )

        for asset_key, original_row in original_by_key.items():
            migrated_row = migrated_by_key[asset_key]
            assert migrated_row.tipo_ativo == original_row.tipo_ativo, (
                f"tipo_ativo diverge para asset_key={asset_key!r}: "
                f"original={original_row.tipo_ativo!r}, migrada={migrated_row.tipo_ativo!r}."
            )
            assert migrated_row.distribuidora == original_row.distribuidora, (
                f"distribuidora diverge para asset_key={asset_key!r}: "
                f"original={original_row.distribuidora!r}, migrada={migrated_row.distribuidora!r}."
            )
            assert migrated_row.regiao == original_row.regiao, (
                f"regiao diverge para asset_key={asset_key!r}: "
                f"original={original_row.regiao!r}, migrada={migrated_row.regiao!r}."
            )
            assert migrated_row.geom_text == original_row.geom_text, (
                f"geometry diverge para asset_key={asset_key!r}: "
                f"original={original_row.geom_text!r}, migrada={migrated_row.geom_text!r}."
            )


class TestMigrationFullyRevertsOnFailureProperty:
    """Feature: carga-lote-particionada, Property 7: Falha durante a
    migração reverte completamente ao estado original.

    **Validates: Requirements 3.2**

    Gera um conjunto arbitrário de Ativos, popula uma tabela legada não
    particionada (DDL antigo) e força uma falha simulada (via `monkeypatch`)
    em uma das etapas internas de `schema.migrate_to_partitioned`
    (`schema._ensure_partition_inline`, chamada dentro da transação
    abrangente para criar cada Partição_de_Ativo a partir das combinações
    distintas de `distribuidora`/`regiao` encontradas na tabela legada).
    Verifica que a exceção é propagada e que a tabela original (estrutura
    não particionada + todos os dados) permanece idêntica ao estado anterior
    à tentativa de migração, sem nenhuma tabela residual `<table>_old`.
    """

    @settings(
        max_examples=100,
        deadline=None,
        suppress_health_check=[HealthCheck.function_scoped_fixture, HealthCheck.too_slow],
    )
    @given(ativos=_ativos_strategy)
    def test_migration_failure_fully_reverts_original_table(self, engine, pg_schema, monkeypatch, ativos):
        layer_name = "POSTE"
        table_name = schema.ASSET_TABLE_SPECS[layer_name].table_name
        qualified_table = f"{pg_schema}.{table_name}"
        qualified_old_table = f"{qualified_table}_old"

        # `pg_schema` é um fixture por-teste (não por-exemplo do Hypothesis):
        # a tabela legada precisa ser recriada do zero em cada exemplo, pelo
        # mesmo motivo documentado em
        # TestMigrationPreservesCountAndValuesProperty acima.
        with engine.begin() as conn:
            conn.execute(sa.text(f"DROP TABLE IF EXISTS {qualified_table} CASCADE"))
            conn.execute(sa.text(f"DROP TABLE IF EXISTS {qualified_old_table} CASCADE"))
        _create_legacy_table(engine, qualified_table)

        # Mesma estratégia de asset_key única por exemplo/Ativo usada no
        # teste da Property 6, para não colidir entre exemplos do Hypothesis
        # nem entre Ativos do próprio exemplo.
        example_salt = abs(hash(tuple(ativos)))
        expected_rows: dict[str, tuple[str, str, str]] = {}
        for index, ((distribuidora, regiao), cod_id) in enumerate(ativos):
            asset_key = f"{layer_name}::{cod_id}_{example_salt}_{index}"
            lon = -46.0 + index * 0.01
            lat = -23.0 + index * 0.01
            _insert_legacy_row(
                engine, qualified_table, layer_name, distribuidora, regiao, asset_key, lon, lat
            )
            expected_rows[asset_key] = (
                distribuidora,
                regiao,
                f"POINT({lon} {lat})",
            )

        original_rows = _fetch_all_rows(engine, qualified_table)
        original_by_key = {row.asset_key: row for row in original_rows}
        assert len(original_by_key) == len(expected_rows), (
            "Falha de setup do teste: número de linhas inseridas na tabela legada "
            f"({len(original_by_key)}) não corresponde ao número de Ativos gerados "
            f"({len(expected_rows)})."
        )

        def _boom(*args, **kwargs):
            raise RuntimeError("Falha simulada em _ensure_partition_inline (teste de propriedade).")

        monkeypatch.setattr(schema, "_ensure_partition_inline", _boom)

        with pytest.raises(RuntimeError):
            schema.migrate_to_partitioned(engine, layer_name, pg_schema)

        # A tabela original com o nome esperado ainda existe e NÃO está
        # particionada — o rollback da transação de `engine.begin()` deve
        # ter restaurado o RENAME de volta ao nome original.
        with engine.connect() as conn:
            table_exists = conn.execute(
                sa.text(
                    "SELECT 1 FROM information_schema.tables "
                    "WHERE table_schema = :pg_schema AND table_name = :table_name"
                ),
                {"pg_schema": pg_schema, "table_name": table_name},
            ).fetchone()
        assert table_exists is not None, (
            f"Tabela original '{qualified_table}' deveria continuar existindo após a "
            "falha simulada durante a migração."
        )
        assert schema.is_partitioned(engine, pg_schema, table_name) is False, (
            f"Tabela original '{qualified_table}' não deveria estar particionada após "
            "uma migração que falhou e foi revertida."
        )

        # Nenhuma tabela residual `<table>_old` deve ter sobrado.
        with engine.connect() as conn:
            old_table_exists = conn.execute(
                sa.text(
                    "SELECT 1 FROM information_schema.tables "
                    "WHERE table_schema = :pg_schema AND table_name = :table_name"
                ),
                {"pg_schema": pg_schema, "table_name": f"{table_name}_old"},
            ).fetchone()
        assert old_table_exists is None, (
            f"Tabela residual '{qualified_old_table}' não deveria existir após rollback "
            "da migração que falhou."
        )

        # Contagem e valores das linhas permanecem idênticos aos inseridos
        # antes da tentativa de migração.
        reverted_rows = _fetch_all_rows(engine, qualified_table)
        reverted_by_key = {row.asset_key: row for row in reverted_rows}

        assert len(reverted_rows) == len(original_rows), (
            f"Contagem total diverge após rollback: original={len(original_rows)}, "
            f"após falha={len(reverted_rows)}."
        )
        assert set(reverted_by_key.keys()) == set(original_by_key.keys()), (
            "Conjunto de asset_key após rollback diverge do conjunto original: "
            f"faltando={set(original_by_key) - set(reverted_by_key)!r}, "
            f"extra={set(reverted_by_key) - set(original_by_key)!r}."
        )
        for asset_key, original_row in original_by_key.items():
            reverted_row = reverted_by_key[asset_key]
            assert reverted_row.tipo_ativo == original_row.tipo_ativo, (
                f"tipo_ativo diverge para asset_key={asset_key!r} após rollback: "
                f"original={original_row.tipo_ativo!r}, revertida={reverted_row.tipo_ativo!r}."
            )
            assert reverted_row.distribuidora == original_row.distribuidora, (
                f"distribuidora diverge para asset_key={asset_key!r} após rollback: "
                f"original={original_row.distribuidora!r}, revertida={reverted_row.distribuidora!r}."
            )
            assert reverted_row.regiao == original_row.regiao, (
                f"regiao diverge para asset_key={asset_key!r} após rollback: "
                f"original={original_row.regiao!r}, revertida={reverted_row.regiao!r}."
            )
            assert reverted_row.geom_text == original_row.geom_text, (
                f"geometry diverge para asset_key={asset_key!r} após rollback: "
                f"original={original_row.geom_text!r}, revertida={reverted_row.geom_text!r}."
            )


class TestMigrationPreservesIndexesPerPartitionProperty:
    """Feature: carga-lote-particionada, Property 8: Migração preserva os
    índices por partição resultante.

    **Validates: Requirements 3.3**

    Gera Ativos distribuídos em N (2 a 5) combinações distintas de
    `(distribuidora, regiao)`, popula uma tabela legada não particionada (DDL
    antigo), migra via `schema.migrate_to_partitioned`, e verifica — via
    `pg_indexes` — que cada uma das N partições resultantes tem o índice
    único cobrindo `(partition_key, asset_key)` (nome `uq_<tabela>_asset_key`,
    propagado da tabela-mãe) e o índice GiST cobrindo `geometry` (nome
    `idx_<tabela>_geometry`), conforme a estrutura real implementada em
    `schema.ddl_for_layer`/`schema.migrate_to_partitioned` (ver decisão (a2)
    do design.md, mesma referência de padrão usada por
    `TestPartitionInheritsColumnsAndConstraints`, task 9.3, em
    `test_properties_partitioning.py`) — não literalmente
    `(distribuidora, regiao, asset_key)` como descrito de forma simplificada
    no texto da task.
    """

    @staticmethod
    def _index_defs(engine: sa.Engine, pg_schema: str, partition_name: str) -> list[sa.Row]:
        with engine.connect() as conn:
            return conn.execute(
                sa.text(
                    "SELECT indexname, indexdef FROM pg_indexes "
                    "WHERE schemaname = :pg_schema AND tablename = :partition_name"
                ),
                {"pg_schema": pg_schema, "partition_name": partition_name},
            ).fetchall()

    # Gera de 2 a 5 combinações distintas de (distribuidora, regiao), cada
    # uma com 1 Ativo, para cobrir explicitamente "N combinações distintas"
    # conforme o texto da task (distinto da estratégia genérica
    # `_ativos_strategy` usada pelas Properties 6/7, que permite 1 a 6 Ativos
    # sem garantir combinações distintas entre si).
    _distinct_partition_keys_strategy = st.lists(
        _partition_key_pair, min_size=2, max_size=5, unique=True
    )

    @settings(
        max_examples=100,
        deadline=None,
        suppress_health_check=[HealthCheck.function_scoped_fixture, HealthCheck.too_slow],
    )
    @given(partition_keys=_distinct_partition_keys_strategy)
    def test_migration_preserves_unique_and_gist_indexes_per_partition(
        self, engine, pg_schema, partition_keys
    ):
        layer_name = "POSTE"
        table_name = schema.ASSET_TABLE_SPECS[layer_name].table_name
        qualified_table = f"{pg_schema}.{table_name}"

        # `pg_schema` é um fixture por-teste (não por-exemplo do Hypothesis):
        # a tabela legada precisa ser recriada do zero em cada exemplo, pelo
        # mesmo motivo documentado em
        # TestMigrationPreservesCountAndValuesProperty acima.
        with engine.begin() as conn:
            conn.execute(sa.text(f"DROP TABLE IF EXISTS {qualified_table} CASCADE"))
            conn.execute(sa.text(f"DROP TABLE IF EXISTS {qualified_table}_old CASCADE"))
        _create_legacy_table(engine, qualified_table)

        # Uma asset_key única por combinação (salt derivado do exemplo,
        # mesma convenção usada pelas Properties 6/7 acima), garantindo N
        # Ativos distribuídos em N combinações distintas de
        # (distribuidora, regiao) — exatamente uma por combinação.
        example_salt = abs(hash(tuple(partition_keys)))
        for index, (distribuidora, regiao) in enumerate(partition_keys):
            asset_key = f"{layer_name}::idx_{example_salt}_{index}"
            lon = -46.0 + index * 0.01
            lat = -23.0 + index * 0.01
            _insert_legacy_row(
                engine, qualified_table, layer_name, distribuidora, regiao, asset_key, lon, lat
            )

        schema.migrate_to_partitioned(engine, layer_name, pg_schema)

        assert schema.is_partitioned(engine, pg_schema, table_name) is True, (
            "Tabela deveria estar particionada após migrate_to_partitioned."
        )

        for distribuidora, regiao in partition_keys:
            partition_name = f"{table_name}_{schema.partition_suffix(distribuidora, regiao)}"
            index_rows = self._index_defs(engine, pg_schema, partition_name)
            index_defs_by_name = {row.indexname: row.indexdef for row in index_rows}

            unique_index_defs = [
                indexdef for indexdef in index_defs_by_name.values()
                if "UNIQUE INDEX" in indexdef.upper()
                and "(partition_key, asset_key)" in indexdef
            ]
            assert unique_index_defs, (
                f"Partição '{partition_name}' (distribuidora={distribuidora!r}, "
                f"regiao={regiao!r}) deveria ter um índice único cobrindo "
                f"(partition_key, asset_key), herdado de 'uq_{table_name}_asset_key' "
                f"na tabela-mãe. Índices encontrados: {index_defs_by_name!r}."
            )

            gist_index_defs = [
                indexdef for indexdef in index_defs_by_name.values()
                if "USING GIST" in indexdef.upper() and "(geometry)" in indexdef
            ]
            assert gist_index_defs, (
                f"Partição '{partition_name}' (distribuidora={distribuidora!r}, "
                f"regiao={regiao!r}) deveria ter um índice GiST cobrindo geometry, "
                f"herdado de 'idx_{table_name}_geometry' na tabela-mãe. "
                f"Índices encontrados: {index_defs_by_name!r}."
            )
