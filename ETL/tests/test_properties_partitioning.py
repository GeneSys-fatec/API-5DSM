"""Property-based tests (Hypothesis) para o particionamento nativo das
Tabelas_de_Ativo e para o comportamento de upsert através das partições
(spec `carga-lote-particionada`, SYS-19).
"""

from __future__ import annotations

import sys
from pathlib import Path

import geopandas as gpd
import pytest
import sqlalchemy as sa
from hypothesis import HealthCheck, assume, given, settings
from hypothesis import strategies as st
from shapely.geometry import Point

_ETL_DIR = Path(__file__).resolve().parent.parent
if str(_ETL_DIR) not in sys.path:
    sys.path.insert(0, str(_ETL_DIR))

import load  # noqa: E402
import schema  # noqa: E402
import transform  # noqa: E402

# Alfabeto restrito a caracteres "razoáveis" de nome de distribuidora/região
# (letras ASCII, dígitos, espaço, hífen e underscore) — evita gerar strings
# adversariais irrelevantes para esta property (ex. caracteres de controle)
# enquanto ainda cobre variações de caixa/espaços relevantes para o
# particionamento.
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


def _build_gdf(cod_id: str, dist_name: str, layer_name: str, regiao: str) -> gpd.GeoDataFrame:
    gdf = gpd.GeoDataFrame(
        {"COD_ID": [cod_id], "geometry": [Point(0.0, 0.0)]},
        geometry="geometry",
        crs="EPSG:4326",
    )
    gdf = transform.add_stable_key(gdf, layer_name=layer_name, dist_name=dist_name, key_col="COD_ID")
    gdf["tipo_ativo"] = layer_name
    gdf["distribuidora"] = dist_name
    gdf["regiao"] = regiao
    return gdf


def _count_child_partitions_matching(
    engine: sa.Engine, pg_schema: str, table_name: str, partition_name: str
) -> int:
    """Conta quantas partições filhas com nome `partition_name` existem como
    filhas de `<pg_schema>.<table_name>` em `pg_catalog.pg_inherits` (usado
    para verificar idempotência de `ensure_partition` — Property 2).
    """
    with engine.connect() as conn:
        rows = conn.execute(
            sa.text(
                "SELECT 1 "
                "FROM pg_catalog.pg_inherits i "
                "JOIN pg_catalog.pg_class child ON child.oid = i.inhrelid "
                "JOIN pg_catalog.pg_class parent ON parent.oid = i.inhparent "
                "JOIN pg_catalog.pg_namespace n ON n.oid = child.relnamespace "
                "WHERE n.nspname = :pg_schema "
                "AND child.relname = :partition_name "
                "AND parent.relname = :table_name"
            ),
            {
                "pg_schema": pg_schema,
                "partition_name": partition_name,
                "table_name": table_name,
            },
        ).fetchall()
    return len(rows)


class TestPartitionCreationIsIdempotentProperty:
    """Feature: carga-lote-particionada, Property 2: Criação de partição é
    idempotente.

    **Validates: Requirements 1.3**

    Gera pares (distribuidora, regiao) e chama `ensure_partition` de 1 a N
    vezes em sequência, verificando que exatamente uma partição existe no
    catálogo após qualquer número de chamadas.
    """

    @settings(
        max_examples=100,
        deadline=None,
        suppress_health_check=[HealthCheck.function_scoped_fixture],
    )
    @given(partition_key=_partition_key_pair, call_count=st.integers(min_value=1, max_value=8))
    def test_ensure_partition_called_n_times_results_in_exactly_one_partition(
        self, engine, pg_schema, partition_key, call_count
    ):
        distribuidora, regiao = partition_key
        layer_name = "POSTE"

        schema.ensure_asset_table(engine, layer_name, pg_schema)
        table_name = schema.ASSET_TABLE_SPECS[layer_name].table_name
        partition_name = f"{table_name}_{schema.partition_suffix(distribuidora, regiao)}"

        for _ in range(call_count):
            schema.ensure_partition(engine, layer_name, pg_schema, distribuidora, regiao)

        partition_count = _count_child_partitions_matching(engine, pg_schema, table_name, partition_name)

        assert partition_count == 1, (
            f"Esperada exatamente 1 partição '{partition_name}' após {call_count} "
            f"chamada(s) de ensure_partition para (distribuidora={distribuidora!r}, "
            f"regiao={regiao!r}), obtido {partition_count}."
        )


class TestAssetKeyCrossPartitionConflictProperty:
    """Property 5: Conflito de Asset_Key entre partições diferentes é
    rejeitado sem alterar o registro existente.

    Validates: Requirements 2.1, 2.3
    """

    @settings(
        max_examples=100,
        deadline=None,
        suppress_health_check=[HealthCheck.function_scoped_fixture],
    )
    @given(
        pair_a=_partition_key_pair,
        pair_b=_partition_key_pair,
        cod_id=_cod_id_strategy,
    )
    def test_conflicting_asset_key_across_partitions_is_rejected(
        self, engine, pg_schema, pair_a, pair_b, cod_id
    ):
        dist_a, regiao_a = pair_a
        dist_b, regiao_b = pair_b
        layer_name = "POSTE"

        # A asset_key é derivada de (layer_name, distribuidora, cod_id) — para
        # garantir uma asset_key em comum entre as duas Chaves_de_Particionamento
        # geradas, usamos a mesma distribuidora e cod_id em ambos os pares,
        # variando apenas a região. Isso ainda cobre o requisito: duas
        # Chaves_de_Particionamento distintas (a combinação (distribuidora,
        # regiao) difere) compartilhando a mesma Asset_Key.
        dist_b = dist_a
        if regiao_a == regiao_b:
            regiao_b = regiao_b + "_alt"

        # `pg_schema` é um fixture por-teste (não por-exemplo do Hypothesis):
        # todos os exemplos gerados por `@given` reutilizam o mesmo schema
        # dentro desta mesma execução de teste. Um `cod_id` curto gerado em um
        # exemplo anterior poderia coincidir com `dist_a`/`regiao_a` de um
        # exemplo posterior, produzindo a MESMA asset_key por acidente entre
        # exemplos não relacionados — um falso positivo do teste, não um bug
        # da feature. Um sufixo único por exemplo (baseado no par de
        # partição) isola os dados de cada exemplo dentro do schema
        # compartilhado.
        example_salt = f"{dist_a}|{regiao_a}|{dist_b}|{regiao_b}"
        cod_id = f"{cod_id}_{abs(hash(example_salt))}"

        gdf_original = _build_gdf(cod_id=cod_id, dist_name=dist_a, layer_name=layer_name, regiao=regiao_a)
        asset_key = gdf_original["asset_key"].iloc[0]

        load.upsert_layer(
            gdf_original, layer_name=layer_name, key_col="COD_ID", engine=engine, pg_schema=pg_schema
        )

        gdf_conflicting = _build_gdf(cod_id=cod_id, dist_name=dist_b, layer_name=layer_name, regiao=regiao_b)

        with pytest.raises(ValueError) as exc_info:
            load.upsert_layer(
                gdf_conflicting, layer_name=layer_name, key_col="COD_ID", engine=engine, pg_schema=pg_schema
            )

        message = str(exc_info.value)
        assert asset_key in message, (
            f"Mensagem de erro deveria identificar a asset_key em conflito ({asset_key!r}): {message}"
        )
        assert f"{dist_a}::{regiao_a}" in message, (
            f"Mensagem de erro deveria identificar a Chave_de_Particionamento original "
            f"({dist_a}::{regiao_a}): {message}"
        )
        assert f"{dist_b}::{regiao_b}" in message, (
            f"Mensagem de erro deveria identificar a Chave_de_Particionamento em conflito "
            f"({dist_b}::{regiao_b}): {message}"
        )

        with engine.connect() as conn:
            rows = conn.execute(
                sa.text(f"SELECT asset_key, distribuidora, regiao FROM {pg_schema}.poste")
            ).fetchall()

        matching_rows = [row for row in rows if row.asset_key == asset_key]
        assert len(matching_rows) == 1, (
            "O registro original não deveria ter sido duplicado nem removido "
            f"após a tentativa de conflito (linhas encontradas: {matching_rows})."
        )
        assert matching_rows[0].distribuidora == dist_a
        assert matching_rows[0].regiao == regiao_a, (
            "O registro original deveria permanecer na Chave_de_Particionamento "
            f"original ({dist_a}::{regiao_a}), mas está em "
            f"({matching_rows[0].distribuidora}::{matching_rows[0].regiao})."
        )


def _column_snapshot(engine: sa.Engine, pg_schema: str, table_name: str) -> dict[str, tuple]:
    """Retorna um snapshot comparável das colunas de <pg_schema>.<table_name>
    via information_schema.columns: para cada coluna, (data_type, is_nullable,
    udt_name, character_maximum_length), indexado por column_name. Usado para
    comparar a tabela-mãe com uma Partição_de_Ativo (Requisito 1.4, 7.1).
    """
    with engine.connect() as conn:
        rows = conn.execute(
            sa.text(
                "SELECT column_name, data_type, is_nullable, udt_name, "
                "character_maximum_length "
                "FROM information_schema.columns "
                "WHERE table_schema = :pg_schema AND table_name = :table_name"
            ),
            {"pg_schema": pg_schema, "table_name": table_name},
        ).fetchall()
    return {
        row.column_name: (row.data_type, row.is_nullable, row.udt_name, row.character_maximum_length)
        for row in rows
    }


def _geometry_type_and_srid(engine: sa.Engine, pg_schema: str, table_name: str) -> tuple[str, int] | None:
    """Consulta geometry_columns (metadados do PostGIS) para obter o subtipo
    espacial (type) e o SRID da coluna `geometry` de <pg_schema>.<table_name>.
    Retorna None se a tabela não tiver uma entrada em geometry_columns (não
    deveria acontecer para nenhuma Tabela_de_Ativo/Partição_de_Ativo desta
    feature, já que todas têm a coluna `geometry`).
    """
    with engine.connect() as conn:
        row = conn.execute(
            sa.text(
                "SELECT type, srid FROM geometry_columns "
                "WHERE f_table_schema = :pg_schema AND f_table_name = :table_name "
                "AND f_geometry_column = 'geometry'"
            ),
            {"pg_schema": pg_schema, "table_name": table_name},
        ).fetchone()
    return (row.type, row.srid) if row is not None else None


def _check_constraint_defs(engine: sa.Engine, pg_schema: str, table_name: str) -> set[str]:
    """Retorna o conjunto de definições (via pg_get_constraintdef) de todas as
    constraints CHECK definidas sobre <pg_schema>.<table_name> (usado para
    confirmar que a Partição_de_Ativo de SUB herda o CHECK de subtipo de
    geometria da tabela-mãe — Requisito 7.2).
    """
    qualified_table = f"{pg_schema}.{table_name}"
    with engine.connect() as conn:
        rows = conn.execute(
            sa.text(
                "SELECT pg_get_constraintdef(oid) AS def FROM pg_constraint "
                "WHERE conrelid = CAST(:qualified_table AS regclass) AND contype = 'c'"
            ),
            {"qualified_table": qualified_table},
        ).fetchall()
    return {row[0] for row in rows}


layer_and_partition_key_pair = st.tuples(
    st.sampled_from(list(schema.ASSET_TABLE_SPECS.keys())),
    _non_blank_key_text(),
    _non_blank_key_text(),
)


class TestPartitionInheritsColumnsAndConstraints:
    """Feature: carga-lote-particionada, Property 3: Partições herdam a
    estrutura de colunas e constraints da tabela-mãe.

    **Validates: Requirements 1.4, 7.1**
    """

    @settings(
        max_examples=100,
        deadline=None,
        suppress_health_check=[HealthCheck.function_scoped_fixture, HealthCheck.too_slow],
    )
    @given(layer_and_pair=layer_and_partition_key_pair)
    def test_partition_has_same_columns_types_and_constraints_as_parent(
        self, engine, pg_schema, layer_and_pair: tuple[str, str, str]
    ) -> None:
        layer_name, distribuidora, regiao = layer_and_pair
        table_name = schema.ASSET_TABLE_SPECS[layer_name].table_name

        schema.ensure_asset_table(engine, layer_name, pg_schema)
        schema.ensure_partition(engine, layer_name, pg_schema, distribuidora, regiao)

        partition_name = f"{table_name}_{schema.partition_suffix(distribuidora, regiao)}"

        # Mesmas colunas, mesmos tipos e mesma obrigatoriedade de
        # preenchimento (NOT NULL) — Requisito 1.4, 7.1.
        parent_columns = _column_snapshot(engine, pg_schema, table_name)
        partition_columns = _column_snapshot(engine, pg_schema, partition_name)
        assert partition_columns == parent_columns, (
            f"Colunas da partição '{partition_name}' divergem da tabela-mãe "
            f"'{table_name}': partição={partition_columns!r} vs mãe={parent_columns!r}"
        )

        # Mesmo subtipo espacial e mesmo SRID (4326) na coluna geometry —
        # Requisito 7.1.
        parent_geometry = _geometry_type_and_srid(engine, pg_schema, table_name)
        partition_geometry = _geometry_type_and_srid(engine, pg_schema, partition_name)
        assert parent_geometry is not None
        assert partition_geometry == parent_geometry, (
            f"Subtipo espacial/SRID da partição '{partition_name}' ({partition_geometry!r}) "
            f"diverge da tabela-mãe '{table_name}' ({parent_geometry!r})."
        )

        # Quando aplicável (layer SUB), a constraint CHECK de subtipo de
        # geometria também é herdada pela partição — Requisito 7.2.
        spec = schema.ASSET_TABLE_SPECS[layer_name]
        if spec.allowed_subtypes:
            parent_checks = _check_constraint_defs(engine, pg_schema, table_name)
            partition_checks = _check_constraint_defs(engine, pg_schema, partition_name)
            assert parent_checks, (
                f"Esperava ao menos uma constraint CHECK na tabela-mãe '{table_name}' "
                f"(layer {layer_name!r} tem allowed_subtypes definido)."
            )
            assert partition_checks == parent_checks, (
                f"Constraints CHECK da partição '{partition_name}' ({partition_checks!r}) "
                f"divergem da tabela-mãe '{table_name}' ({parent_checks!r})."
            )


class TestUpsertIdempotentWithinSamePartitionKeyProperty:
    """Property 4: Upsert é idempotente dentro da mesma Chave_de_Particionamento.

    Validates: Requirements 2.1, 2.2
    """

    @settings(
        max_examples=100,
        deadline=None,
        suppress_health_check=[HealthCheck.function_scoped_fixture],
    )
    @given(
        partition_key=_partition_key_pair,
        cod_id=_cod_id_strategy,
        coords=st.lists(
            st.tuples(
                st.floats(min_value=-90.0, max_value=90.0, allow_nan=False, allow_infinity=False),
                st.floats(min_value=-90.0, max_value=90.0, allow_nan=False, allow_infinity=False),
            ),
            min_size=1,
            max_size=5,
        ),
    )
    def test_upsert_sequence_same_asset_key_results_in_single_row_with_last_values(
        self, engine, pg_schema, partition_key, cod_id, coords
    ):
        dist_name, regiao = partition_key
        layer_name = "POSTE"
        last_x, last_y = coords[-1]

        # O fixture `pg_schema` é criado uma única vez por invocação da
        # função de teste (não por exemplo do Hypothesis) — como o mesmo
        # teste é executado repetidamente para muitos exemplos dentro dessa
        # mesma invocação, linhas inseridas por um exemplo anterior
        # permaneceriam visíveis para os exemplos seguintes. Isola cada
        # exemplo truncando a Tabela_de_Ativo antes de rodar a sequência de
        # upserts, para que a asserção "exatamente 1 registro com essa
        # asset_key" não seja afetada por dados residuais de outro exemplo.
        schema.ensure_asset_table(engine, layer_name, pg_schema)
        with engine.begin() as conn:
            conn.execute(sa.text(f"TRUNCATE TABLE {pg_schema}.poste"))

        for x, y in coords:
            gdf = gpd.GeoDataFrame(
                {"COD_ID": [cod_id], "geometry": [Point(x, y)]},
                geometry="geometry",
                crs="EPSG:4326",
            )
            gdf = transform.add_stable_key(
                gdf, layer_name=layer_name, dist_name=dist_name, key_col="COD_ID"
            )
            gdf["tipo_ativo"] = layer_name
            gdf["distribuidora"] = dist_name
            gdf["regiao"] = regiao

            load.upsert_layer(
                gdf, layer_name=layer_name, key_col="COD_ID", engine=engine, pg_schema=pg_schema
            )

        expected_asset_key = f"{layer_name}::{dist_name}::{cod_id}"

        with engine.connect() as conn:
            rows = conn.execute(
                sa.text(
                    f"SELECT asset_key, distribuidora, regiao, "
                    f"ST_X(geometry) AS x, ST_Y(geometry) AS y "
                    f"FROM {pg_schema}.poste WHERE asset_key = :asset_key"
                ),
                {"asset_key": expected_asset_key},
            ).fetchall()

        assert len(rows) == 1, (
            f"Esperado exatamente 1 registro para asset_key={expected_asset_key!r} "
            f"após {len(coords)} upsert(s), obtido {len(rows)}."
        )

        row = rows[0]
        assert row.distribuidora == dist_name
        assert row.regiao == regiao
        assert row.x == pytest.approx(last_x)
        assert row.y == pytest.approx(last_y)


class TestPartitionByExactPartitioningKey:
    """Feature: carga-lote-particionada, Property 1: Partição por
    Chave_de_Particionamento exata.

    **Validates: Requirements 1.1, 1.2**

    Para toda combinação de valores de `distribuidora` e `regiao` (incluindo
    combinações que diferem apenas em maiúsculas/minúsculas ou espaços),
    inserir um Ativo com essa combinação resulta em exatamente uma
    Partição_de_Ativo dedicada a essa combinação exata, e Ativos com
    combinações que diferem em caixa ou espaços residem em partições
    distintas.
    """

    @settings(
        max_examples=100,
        deadline=None,
        suppress_health_check=[HealthCheck.function_scoped_fixture],
    )
    @given(partition_key=_partition_key_pair, cod_id=_cod_id_strategy)
    def test_exact_combination_maps_to_exactly_one_partition(
        self, engine, pg_schema, partition_key, cod_id
    ):
        dist_name, regiao = partition_key
        layer_name = "POSTE"

        # `pg_schema` é um fixture por-teste (não por-exemplo do Hypothesis):
        # todos os exemplos gerados por `@given` reutilizam o mesmo schema
        # dentro desta mesma execução de teste. Salta o cod_id com base na
        # combinação gerada para evitar colisão de asset_key entre exemplos
        # não relacionados (mesmo padrão usado em
        # TestAssetKeyCrossPartitionConflictProperty).
        cod_id = f"{cod_id}_{abs(hash((dist_name, regiao)))}"

        gdf = _build_gdf(cod_id=cod_id, dist_name=dist_name, layer_name=layer_name, regiao=regiao)
        load.upsert_layer(
            gdf, layer_name=layer_name, key_col="COD_ID", engine=engine, pg_schema=pg_schema
        )

        table_name = schema.ASSET_TABLE_SPECS[layer_name].table_name
        partition_name = f"{table_name}_{schema.partition_suffix(dist_name, regiao)}"

        partition_count = _count_child_partitions_matching(engine, pg_schema, table_name, partition_name)

        assert partition_count == 1, (
            f"Esperada exatamente 1 partição '{partition_name}' para a combinação exata "
            f"(distribuidora={dist_name!r}, regiao={regiao!r}), obtido {partition_count}."
        )

    @settings(
        max_examples=100,
        deadline=None,
        suppress_health_check=[HealthCheck.function_scoped_fixture],
    )
    @given(
        partition_key=_partition_key_pair,
        cod_id_a=_cod_id_strategy,
        cod_id_b=_cod_id_strategy,
        case_variant=st.booleans(),
    )
    def test_case_or_whitespace_variants_reside_in_distinct_partitions(
        self, engine, pg_schema, partition_key, cod_id_a, cod_id_b, case_variant
    ):
        dist_name, regiao = partition_key
        layer_name = "POSTE"

        # Deriva uma segunda combinação que difere da primeira apenas em
        # caixa (upper/lower) ou em espaços adicionais nas bordas —
        # continua sendo uma combinação de Chave_de_Particionamento
        # sintaticamente diferente da original (correspondência exata,
        # sensível a caixa e espaços, conforme Requisito 1.1).
        if case_variant:
            dist_variant = dist_name.swapcase()
            regiao_variant = regiao.swapcase()
        else:
            dist_variant = f" {dist_name} "
            regiao_variant = f" {regiao} "

        # Se a variação de caixa não mudar nada (ex. entrada só com dígitos
        # ou espaços), força a variação por espaços, que sempre resulta em
        # texto distinto do original.
        if dist_variant == dist_name and regiao_variant == regiao:
            dist_variant = f" {dist_name} "
            regiao_variant = f" {regiao} "

        assume((dist_variant, regiao_variant) != (dist_name, regiao))

        table_name = schema.ASSET_TABLE_SPECS[layer_name].table_name

        # `pg_schema` é um fixture por-teste (não por-exemplo do Hypothesis):
        # todos os exemplos gerados por `@given` reutilizam o mesmo schema
        # dentro desta mesma execução de teste. Salta os cod_ids com base na
        # combinação gerada para evitar colisão de asset_key entre exemplos
        # não relacionados, e entre os dois grupos (a asset_key é derivada de
        # layer_name/distribuidora/cod_id, não de regiao — sem o salt, dois
        # exemplos distintos, ou os dois grupos do mesmo exemplo quando
        # distribuidora não muda de caixa, poderiam colidir na mesma
        # asset_key e acionar a checagem de conflito cross-partição,
        # produzindo um falso positivo do teste).
        example_salt = abs(hash((dist_name, regiao, dist_variant, regiao_variant)))
        cod_id_a = f"{cod_id_a}_{example_salt}_a"
        cod_id_b = f"{cod_id_b}_{example_salt}_b"

        gdf_a = _build_gdf(cod_id=cod_id_a, dist_name=dist_name, layer_name=layer_name, regiao=regiao)
        load.upsert_layer(
            gdf_a, layer_name=layer_name, key_col="COD_ID", engine=engine, pg_schema=pg_schema
        )

        gdf_b = _build_gdf(cod_id=cod_id_b, dist_name=dist_variant, layer_name=layer_name, regiao=regiao_variant)
        load.upsert_layer(
            gdf_b, layer_name=layer_name, key_col="COD_ID", engine=engine, pg_schema=pg_schema
        )

        partition_name_a = f"{table_name}_{schema.partition_suffix(dist_name, regiao)}"
        partition_name_b = f"{table_name}_{schema.partition_suffix(dist_variant, regiao_variant)}"

        assert partition_name_a != partition_name_b, (
            f"Combinações que diferem em caixa/espaços deveriam residir em partições "
            f"distintas, mas ambas resultaram no mesmo nome de partição "
            f"({partition_name_a!r}): original=(distribuidora={dist_name!r}, "
            f"regiao={regiao!r}) vs variante=(distribuidora={dist_variant!r}, "
            f"regiao={regiao_variant!r})."
        )

        count_a = _count_child_partitions_matching(engine, pg_schema, table_name, partition_name_a)
        count_b = _count_child_partitions_matching(engine, pg_schema, table_name, partition_name_b)

        assert count_a == 1, (
            f"Esperada exatamente 1 partição '{partition_name_a}' para a combinação "
            f"original (distribuidora={dist_name!r}, regiao={regiao!r}), obtido {count_a}."
        )
        assert count_b == 1, (
            f"Esperada exatamente 1 partição '{partition_name_b}' para a combinação "
            f"variante (distribuidora={dist_variant!r}, regiao={regiao_variant!r}), "
            f"obtido {count_b}."
        )
