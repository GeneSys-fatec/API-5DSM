from __future__ import annotations

import hashlib
import re
import sys
from pathlib import Path

import pytest

_ETL_DIR = Path(__file__).resolve().parent.parent
if str(_ETL_DIR) not in sys.path:
    sys.path.insert(0, str(_ETL_DIR))

import schema  # noqa: E402


def _extract_column_definitions_block(create_table_stmt: str) -> str:
    """Extrai o bloco entre o `(` que abre a lista de colunas e o `)` que a
    fecha (o primeiro `(` do statement), ignorando qualquer cláusula que vier
    depois dele (ex. `PARTITION BY LIST (...)`), contando parênteses para
    encontrar o `)` correspondente em vez de assumir que é o último do texto.
    """
    start = create_table_stmt.index("(")
    depth = 0
    for index in range(start, len(create_table_stmt)):
        char = create_table_stmt[index]
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return create_table_stmt[start + 1:index]
    raise ValueError("Parênteses desbalanceados no CREATE TABLE fornecido.")


def _extract_top_level_column_names(create_table_stmt: str) -> list[str]:
    body = _extract_column_definitions_block(create_table_stmt)
    columns: list[str] = []
    depth = 0
    for line in body.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if depth == 0:
            token = stripped.rstrip(",")
            if not token.upper().startswith("CONSTRAINT"):
                columns.append(token.split()[0])
        depth += stripped.count("(") - stripped.count(")")
    return columns


class TestPartitionSuffix:

    def test_same_input_called_twice_produces_same_suffix(self):
        first = schema.partition_suffix("ENEL_SP", "SUDESTE")
        second = schema.partition_suffix("ENEL_SP", "SUDESTE")

        assert first == second

    @pytest.mark.parametrize(
        "distribuidora, regiao",
        [
            ("ENEL-SP", "SUDESTE"),
            ("ENEL_SP", "São Paulo"),
            ("Companhia Energética-Sul", "Região Sul"),
        ],
    )
    def test_suffix_contains_only_allowed_characters(self, distribuidora, regiao):
        suffix = schema.partition_suffix(distribuidora, regiao)

        assert re.fullmatch(r"[a-z0-9_]+", suffix), (
            f"Sufixo {suffix!r} contém caracteres fora de [a-z0-9_]."
        )

    def test_suffix_respects_63_character_limit_for_long_inputs(self):
        distribuidora = "DISTRIBUIDORA_" + "X" * 100
        regiao = "REGIAO_" + "Y" * 100

        suffix = schema.partition_suffix(distribuidora, regiao)

        assert len(suffix.encode("utf-8")) <= 63

    def test_suffix_ends_with_stable_hash_even_when_truncated(self):
        distribuidora = "DISTRIBUIDORA_" + "X" * 100
        regiao = "REGIAO_" + "Y" * 100

        suffix = schema.partition_suffix(distribuidora, regiao)

        digest = hashlib.sha1(f"{distribuidora}|{regiao}".encode("utf-8")).hexdigest()[:8]
        assert suffix.endswith(digest)

    def test_slugs_that_normalize_to_same_value_produce_distinct_suffixes(self):
        suffix_hyphen = schema.partition_suffix("ENEL-SP", "SUDESTE")
        suffix_underscore = schema.partition_suffix("ENEL_SP", "SUDESTE")

        assert suffix_hyphen != suffix_underscore


class TestGetSpec:

    def test_get_spec_poste_returns_correct_spec(self):
        spec = schema.get_spec("POSTE")

        assert spec == schema.ASSET_TABLE_SPECS["POSTE"]
        assert spec.layer == "POSTE"
        assert spec.table_name == "poste"
        assert spec.geometry_type == "Point"
        assert spec.allowed_subtypes is None

    def test_get_spec_layer_inexistente_raises_key_error(self):
        with pytest.raises(KeyError):
            schema.get_spec("LAYER_INEXISTENTE")

    def test_get_spec_key_error_message_lists_valid_layers(self):
        with pytest.raises(KeyError) as exc_info:
            schema.get_spec("LAYER_INEXISTENTE")

        message = str(exc_info.value)
        for layer in schema.ASSET_TABLE_SPECS:
            assert layer in message


class TestAssetTableSpecs:

    def test_contains_all_expected_layers(self):
        expected_layers = {"POSTE", "SUB", "UCBT", "UCMT", "SSDBT", "SSDMT", "SSDAT"}

        assert set(schema.ASSET_TABLE_SPECS.keys()) == expected_layers

    def test_each_spec_key_matches_its_own_layer_field(self):
        for layer_name, spec in schema.ASSET_TABLE_SPECS.items():
            assert spec.layer == layer_name


class TestDdlForLayerPoste:

    def test_contains_create_table_for_bdgd_poste(self):
        statements = schema.ddl_for_layer("POSTE", "bdgd")
        create_table = statements[0]

        assert "CREATE TABLE IF NOT EXISTS bdgd.poste" in create_table

    def test_contains_point_geometry_column(self):
        statements = schema.ddl_for_layer("POSTE", "bdgd")
        create_table = statements[0]

        assert "GEOMETRY(Point, 4326)" in create_table

    def test_does_not_contain_subtype_check(self):
        statements = schema.ddl_for_layer("POSTE", "bdgd")
        create_table = statements[0]

        assert "CHECK" not in create_table

    def test_partition_by_list_partition_key_column(self):
        statements = schema.ddl_for_layer("POSTE", "bdgd")
        create_table = statements[0]

        assert "partition_key  TEXT NOT NULL" in create_table
        assert "PARTITION BY LIST (partition_key)" in create_table

    def test_id_column_is_not_primary_key(self):
        statements = schema.ddl_for_layer("POSTE", "bdgd")
        create_table = statements[0]

        assert "PRIMARY KEY" not in create_table
        assert "id             BIGSERIAL NOT NULL" in create_table


class TestDdlForLayerSub:

    def test_contains_geometry_geometry_column(self):
        statements = schema.ddl_for_layer("SUB", "bdgd")
        create_table = statements[0]

        assert "GEOMETRY(Geometry, 4326)" in create_table

    def test_contains_check_with_the_three_expected_subtypes(self):
        statements = schema.ddl_for_layer("SUB", "bdgd")
        create_table = statements[0]

        assert "CHECK" in create_table
        assert "ST_GeometryType(geometry) IN" in create_table
        assert "'ST_Point'" in create_table
        assert "'ST_Polygon'" in create_table
        assert "'ST_MultiPolygon'" in create_table

    def test_partition_by_list_partition_key_column(self):
        statements = schema.ddl_for_layer("SUB", "bdgd")
        create_table = statements[0]

        assert "PARTITION BY LIST (partition_key)" in create_table


class TestDdlForLayerAllLayers:

    EXPECTED_COLUMNS = [
        "id", "tipo_ativo", "distribuidora", "regiao", "asset_key", "partition_key", "geometry",
    ]

    @pytest.mark.parametrize("layer_name", list(schema.ASSET_TABLE_SPECS.keys()))
    def test_create_table_has_exactly_the_expected_columns(self, layer_name):
        statements = schema.ddl_for_layer(layer_name, "bdgd")
        create_table = statements[0]

        columns = _extract_top_level_column_names(create_table)

        assert columns == self.EXPECTED_COLUMNS

    @pytest.mark.parametrize("layer_name", list(schema.ASSET_TABLE_SPECS.keys()))
    def test_indexes_reference_the_correct_table_name(self, layer_name):
        table = schema.ASSET_TABLE_SPECS[layer_name].table_name
        statements = schema.ddl_for_layer(layer_name, "bdgd")

        assert len(statements) == 3
        _, unique_index, gist_index = statements

        assert f"CREATE UNIQUE INDEX IF NOT EXISTS uq_{table}_asset_key" in unique_index
        assert f"ON bdgd.{table} (partition_key, asset_key)" in unique_index

        assert f"CREATE INDEX IF NOT EXISTS idx_{table}_geometry" in gist_index
        assert f"ON bdgd.{table} USING GIST (geometry)" in gist_index

    @pytest.mark.parametrize("layer_name", list(schema.ASSET_TABLE_SPECS.keys()))
    def test_create_table_is_partitioned_by_list_partition_key_column(self, layer_name):
        statements = schema.ddl_for_layer(layer_name, "bdgd")
        create_table = statements[0]

        assert "PARTITION BY LIST (partition_key)" in create_table

    @pytest.mark.parametrize("layer_name", list(schema.ASSET_TABLE_SPECS.keys()))
    def test_id_column_is_not_primary_key(self, layer_name):
        statements = schema.ddl_for_layer(layer_name, "bdgd")
        create_table = statements[0]

        assert "PRIMARY KEY" not in create_table


class TestEnsureAssetTableIntegration:

    EXPECTED_COLUMNS = {
        "id": {"data_type": "bigint", "is_nullable": "NO"},
        "tipo_ativo": {"data_type": "text", "is_nullable": "NO"},
        "distribuidora": {"data_type": "text", "is_nullable": "NO"},
        "regiao": {"data_type": "text", "is_nullable": "NO"},
        "asset_key": {"data_type": "text", "is_nullable": "NO"},
        "partition_key": {"data_type": "text", "is_nullable": "NO"},
        "geometry": {"data_type": "USER-DEFINED", "is_nullable": "NO", "udt_name": "geometry"},
    }

    @pytest.mark.parametrize("layer_name", list(schema.ASSET_TABLE_SPECS.keys()))
    def test_ensure_asset_table_creates_table_with_expected_columns(self, engine, pg_schema, layer_name):
        import sqlalchemy as sa  # noqa: PLC0415

        schema.ensure_asset_table(engine, layer_name, pg_schema)

        table_name = schema.ASSET_TABLE_SPECS[layer_name].table_name
        with engine.connect() as conn:
            rows = conn.execute(
                sa.text(
                    "SELECT column_name, data_type, is_nullable, udt_name "
                    "FROM information_schema.columns "
                    "WHERE table_schema = :pg_schema AND table_name = :table_name"
                ),
                {"pg_schema": pg_schema, "table_name": table_name},
            ).fetchall()

        actual_columns = {row.column_name: row for row in rows}

        assert set(actual_columns.keys()) == set(self.EXPECTED_COLUMNS.keys())

        for column_name, expected in self.EXPECTED_COLUMNS.items():
            actual = actual_columns[column_name]
            assert actual.data_type == expected["data_type"], (
                f"{layer_name}.{column_name}: esperado data_type={expected['data_type']!r}, "
                f"obtido {actual.data_type!r}"
            )
            assert actual.is_nullable == expected["is_nullable"], (
                f"{layer_name}.{column_name}: esperado is_nullable={expected['is_nullable']!r}, "
                f"obtido {actual.is_nullable!r}"
            )
            if "udt_name" in expected:
                assert actual.udt_name == expected["udt_name"], (
                    f"{layer_name}.{column_name}: esperado udt_name={expected['udt_name']!r}, "
                    f"obtido {actual.udt_name!r}"
                )


def _snapshot_table_structure(engine, pg_schema: str, table_name: str) -> dict:
    import sqlalchemy as sa  # noqa: PLC0415

    qualified_table = f"{pg_schema}.{table_name}"

    with engine.connect() as conn:
        columns = conn.execute(
            sa.text(
                "SELECT column_name, data_type, is_nullable, udt_name, character_maximum_length "
                "FROM information_schema.columns "
                "WHERE table_schema = :pg_schema AND table_name = :table_name "
                "ORDER BY ordinal_position"
            ),
            {"pg_schema": pg_schema, "table_name": table_name},
        ).fetchall()

        indexes = conn.execute(
            sa.text(
                "SELECT indexname, indexdef FROM pg_indexes "
                "WHERE schemaname = :pg_schema AND tablename = :table_name "
                "ORDER BY indexname"
            ),
            {"pg_schema": pg_schema, "table_name": table_name},
        ).fetchall()

        constraints = conn.execute(
            sa.text(
                "SELECT conname, pg_get_constraintdef(oid) AS def "
                "FROM pg_constraint "
                "WHERE conrelid = CAST(:qualified_table AS regclass) "
                "ORDER BY conname"
            ),
            {"qualified_table": qualified_table},
        ).fetchall()

    return {
        "columns": [tuple(row) for row in columns],
        "indexes": [tuple(row) for row in indexes],
        "constraints": [tuple(row) for row in constraints],
    }


class TestEnsureAssetTableIdempotency:

    @pytest.mark.parametrize("layer_name", list(schema.ASSET_TABLE_SPECS.keys()))
    def test_second_call_is_noop_and_structure_is_identical(self, engine, pg_schema, layer_name):
        table_name = schema.ASSET_TABLE_SPECS[layer_name].table_name

        schema.ensure_asset_table(engine, layer_name, pg_schema)
        structure_after_first_call = _snapshot_table_structure(engine, pg_schema, table_name)

        schema.ensure_asset_table(engine, layer_name, pg_schema)
        structure_after_second_call = _snapshot_table_structure(engine, pg_schema, table_name)

        assert structure_after_second_call == structure_after_first_call, (
            f"Estrutura de '{pg_schema}.{table_name}' mudou após a segunda chamada de "
            f"ensure_asset_table para a layer {layer_name!r}."
        )


class TestAssetKeyUniqueIndexSupportsOnConflict:

    def test_on_conflict_asset_key_upserts_single_row(self, engine, pg_schema):
        import sqlalchemy as sa  # noqa: PLC0415

        schema.ensure_asset_table(engine, "POSTE", pg_schema)
        table_name = schema.ASSET_TABLE_SPECS["POSTE"].table_name
        qualified_table = f"{pg_schema}.{table_name}"
        schema.ensure_partition(engine, "POSTE", pg_schema, "DIST_A", "REGIAO_1")

        insert_sql = sa.text(
            f"""
            INSERT INTO {qualified_table} (tipo_ativo, distribuidora, regiao, asset_key, partition_key, geometry)
            VALUES (
                :tipo_ativo, :distribuidora, :regiao, :asset_key, :partition_key,
                ST_SetSRID(ST_MakePoint(:lon, :lat), {schema.SRID})
            )
            ON CONFLICT (partition_key, asset_key) DO UPDATE SET
                tipo_ativo = EXCLUDED.tipo_ativo,
                distribuidora = EXCLUDED.distribuidora,
                regiao = EXCLUDED.regiao,
                geometry = EXCLUDED.geometry
            """
        )

        with engine.begin() as conn:
            conn.execute(
                insert_sql,
                {
                    "tipo_ativo": "POSTE",
                    "distribuidora": "DIST_A",
                    "regiao": "REGIAO_1",
                    "asset_key": "POSTE::123",
                    "partition_key": "DIST_A::REGIAO_1",
                    "lon": -46.0,
                    "lat": -23.0,
                },
            )
            conn.execute(
                insert_sql,
                {
                    "tipo_ativo": "POSTE",
                    "distribuidora": "DIST_A",
                    "regiao": "REGIAO_1",
                    "asset_key": "POSTE::123",
                    "partition_key": "DIST_A::REGIAO_1",
                    "lon": -46.5,
                    "lat": -23.5,
                },
            )

        with engine.connect() as conn:
            rows = conn.execute(
                sa.text(
                    f"SELECT tipo_ativo, distribuidora, regiao FROM {qualified_table} "
                    f"WHERE asset_key = :asset_key"
                ),
                {"asset_key": "POSTE::123"},
            ).fetchall()

        assert len(rows) == 1, (
            f"Esperado exatamente 1 linha para asset_key='POSTE::123' após dois "
            f"INSERT ... ON CONFLICT, obtido {len(rows)}."
        )

        with engine.connect() as conn:
            geom_row = conn.execute(
                sa.text(
                    f"SELECT ST_AsText(geometry) AS geom FROM {qualified_table} "
                    f"WHERE asset_key = :asset_key"
                ),
                {"asset_key": "POSTE::123"},
            ).fetchone()

        assert geom_row.geom == "POINT(-46.5 -23.5)", (
            "A geometria deveria refletir o segundo INSERT (update via ON CONFLICT), "
            f"obtido {geom_row.geom!r}."
        )


class TestGeometryGistIndexExistsInPgIndexes:

    @pytest.mark.parametrize("layer_name", list(schema.ASSET_TABLE_SPECS.keys()))
    def test_idx_geometry_exists_and_uses_gist(self, engine, pg_schema, layer_name):
        import sqlalchemy as sa  # noqa: PLC0415

        schema.ensure_asset_table(engine, layer_name, pg_schema)
        table_name = schema.ASSET_TABLE_SPECS[layer_name].table_name
        index_name = f"idx_{table_name}_geometry"

        with engine.connect() as conn:
            row = conn.execute(
                sa.text(
                    "SELECT indexdef FROM pg_indexes "
                    "WHERE schemaname = :pg_schema AND tablename = :table_name "
                    "AND indexname = :index_name"
                ),
                {"pg_schema": pg_schema, "table_name": table_name, "index_name": index_name},
            ).fetchone()

        assert row is not None, (
            f"Índice '{index_name}' não encontrado em pg_indexes para "
            f"'{pg_schema}.{table_name}'."
        )
        assert "gist" in row.indexdef.lower(), (
            f"Índice '{index_name}' encontrado, mas indexdef não usa GiST: {row.indexdef!r}"
        )


class TestSubGeometryCheckConstraint:

    def _insert_sub(self, engine, qualified_table: str, asset_key: str, wkt: str) -> None:
        import sqlalchemy as sa  # noqa: PLC0415

        insert_sql = sa.text(
            f"""
            INSERT INTO {qualified_table} (tipo_ativo, distribuidora, regiao, asset_key, partition_key, geometry)
            VALUES (
                :tipo_ativo, :distribuidora, :regiao, :asset_key, :partition_key,
                ST_GeomFromText(:wkt, {schema.SRID})
            )
            """
        )
        with engine.begin() as conn:
            conn.execute(
                insert_sql,
                {
                    "tipo_ativo": "SUB",
                    "distribuidora": "DIST_A",
                    "regiao": "REGIAO_1",
                    "asset_key": asset_key,
                    "partition_key": "DIST_A::REGIAO_1",
                    "wkt": wkt,
                },
            )

    def test_point_and_polygon_accepted_linestring_rejected(self, engine, pg_schema):
        import sqlalchemy as sa  # noqa: PLC0415

        schema.ensure_asset_table(engine, "SUB", pg_schema)
        table_name = schema.ASSET_TABLE_SPECS["SUB"].table_name
        qualified_table = f"{pg_schema}.{table_name}"
        schema.ensure_partition(engine, "SUB", pg_schema, "DIST_A", "REGIAO_1")

        self._insert_sub(engine, qualified_table, "SUB::POINT_1", "POINT(-46.0 -23.0)")

        self._insert_sub(
            engine,
            qualified_table,
            "SUB::POLYGON_1",
            "POLYGON((-46.0 -23.0, -46.1 -23.0, -46.1 -23.1, -46.0 -23.1, -46.0 -23.0))",
        )

        with engine.connect() as conn:
            count = conn.execute(
                sa.text(f"SELECT COUNT(*) FROM {qualified_table}")
            ).scalar_one()
        assert count == 2

        with pytest.raises(sa.exc.IntegrityError):
            self._insert_sub(
                engine,
                qualified_table,
                "SUB::LINESTRING_1",
                "LINESTRING(-46.0 -23.0, -46.1 -23.1)",
            )

        with engine.connect() as conn:
            count_after_failed_insert = conn.execute(
                sa.text(f"SELECT COUNT(*) FROM {qualified_table}")
            ).scalar_one()
        assert count_after_failed_insert == 2


class TestEnsurePartitionIntegration:

    def test_ensure_partition_creates_expected_partition(self, engine, pg_schema):
        import sqlalchemy as sa  # noqa: PLC0415

        schema.ensure_asset_table(engine, "POSTE", pg_schema)
        table_name = schema.ASSET_TABLE_SPECS["POSTE"].table_name

        schema.ensure_partition(engine, "POSTE", pg_schema, "ENEL_SP", "SUDESTE")

        partition_name = f"{table_name}_{schema.partition_suffix('ENEL_SP', 'SUDESTE')}"

        with engine.connect() as conn:
            row = conn.execute(
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
            ).fetchone()

        assert row is not None, (
            f"Partição '{pg_schema}.{partition_name}' não encontrada como filha de "
            f"'{pg_schema}.{table_name}' em pg_inherits."
        )

    def test_ensure_partition_called_twice_is_idempotent(self, engine, pg_schema):
        import sqlalchemy as sa  # noqa: PLC0415

        schema.ensure_asset_table(engine, "POSTE", pg_schema)
        table_name = schema.ASSET_TABLE_SPECS["POSTE"].table_name
        partition_name = f"{table_name}_{schema.partition_suffix('ENEL_SP', 'SUDESTE')}"

        schema.ensure_partition(engine, "POSTE", pg_schema, "ENEL_SP", "SUDESTE")
        schema.ensure_partition(engine, "POSTE", pg_schema, "ENEL_SP", "SUDESTE")

        with engine.connect() as conn:
            rows = conn.execute(
                sa.text(
                    "SELECT 1 "
                    "FROM pg_catalog.pg_inherits i "
                    "JOIN pg_catalog.pg_class child ON child.oid = i.inhrelid "
                    "JOIN pg_catalog.pg_namespace n ON n.oid = child.relnamespace "
                    "WHERE n.nspname = :pg_schema AND child.relname = :partition_name"
                ),
                {"pg_schema": pg_schema, "partition_name": partition_name},
            ).fetchall()

        assert len(rows) == 1, (
            f"Esperada exatamente 1 partição '{partition_name}' após duas chamadas de "
            f"ensure_partition, obtido {len(rows)}."
        )

    @pytest.mark.parametrize(
        "distribuidora, regiao",
        [
            (None, "SUDESTE"),
            ("", "SUDESTE"),
            ("   ", "SUDESTE"),
            ("ENEL_SP", None),
            ("ENEL_SP", ""),
            ("ENEL_SP", "   "),
        ],
    )
    def test_ensure_partition_with_blank_key_raises_value_error_without_touching_db(
        self, engine, pg_schema, distribuidora, regiao
    ):
        import sqlalchemy as sa  # noqa: PLC0415

        schema.ensure_asset_table(engine, "POSTE", pg_schema)
        table_name = schema.ASSET_TABLE_SPECS["POSTE"].table_name

        with pytest.raises(ValueError):
            schema.ensure_partition(engine, "POSTE", pg_schema, distribuidora, regiao)

        with engine.connect() as conn:
            rows = conn.execute(
                sa.text(
                    "SELECT 1 "
                    "FROM pg_catalog.pg_inherits i "
                    "JOIN pg_catalog.pg_class child ON child.oid = i.inhrelid "
                    "JOIN pg_catalog.pg_namespace n ON n.oid = child.relnamespace "
                    "WHERE n.nspname = :pg_schema"
                ),
                {"pg_schema": pg_schema},
            ).fetchall()

        assert rows == [], (
            f"Nenhuma partição deveria ter sido criada em '{pg_schema}.{table_name}' "
            f"para distribuidora={distribuidora!r}, regiao={regiao!r}, mas encontrado {rows!r}."
        )


class TestEnsureAllAssetTablesSubset:

    def test_only_requested_layer_table_is_created(self, engine, pg_schema):
        import sqlalchemy as sa  # noqa: PLC0415

        schema.ensure_all_asset_tables(engine, pg_schema, layers=["POSTE"])

        with engine.connect() as conn:
            rows = conn.execute(
                sa.text(
                    "SELECT table_name FROM information_schema.tables "
                    "WHERE table_schema = :pg_schema"
                ),
                {"pg_schema": pg_schema},
            ).fetchall()

        table_names = {row.table_name for row in rows}

        assert table_names == {"poste"}
        for other_table in ("sub", "ucbt", "ucmt", "ssdmt"):
            assert other_table not in table_names


class TestMigrateToPartitioned:
    """Testes de integração para `migrate_to_partitioned` e o roteamento de 3
    ramos em `ensure_asset_table` (tasks 5.1/5.2 do carga-lote-particionada).
    """

    LEGACY_DDL = (
        "CREATE TABLE {qualified_table} ("
        "id BIGSERIAL PRIMARY KEY, "
        "tipo_ativo TEXT NOT NULL, "
        "distribuidora TEXT NOT NULL, "
        "regiao TEXT NOT NULL, "
        "asset_key TEXT NOT NULL UNIQUE, "
        "geometry GEOMETRY(Point,4326) NOT NULL"
        ")"
    )

    def _create_legacy_table(self, engine, qualified_table: str) -> None:
        import sqlalchemy as sa  # noqa: PLC0415

        with engine.begin() as conn:
            conn.execute(sa.text(self.LEGACY_DDL.format(qualified_table=qualified_table)))

    def _insert_legacy_row(
        self, engine, qualified_table: str, distribuidora: str, regiao: str,
        asset_key: str, lon: float, lat: float,
    ) -> None:
        import sqlalchemy as sa  # noqa: PLC0415

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
                    "tipo_ativo": "POSTE",
                    "distribuidora": distribuidora,
                    "regiao": regiao,
                    "asset_key": asset_key,
                    "lon": lon,
                    "lat": lat,
                },
            )

    def _count_child_partitions(self, engine, pg_schema: str, table_name: str) -> int:
        import sqlalchemy as sa  # noqa: PLC0415

        with engine.connect() as conn:
            rows = conn.execute(
                sa.text(
                    "SELECT child.relname "
                    "FROM pg_catalog.pg_inherits i "
                    "JOIN pg_catalog.pg_class child ON child.oid = i.inhrelid "
                    "JOIN pg_catalog.pg_class parent ON parent.oid = i.inhparent "
                    "JOIN pg_catalog.pg_namespace n ON n.oid = child.relnamespace "
                    "WHERE n.nspname = :pg_schema AND parent.relname = :table_name"
                ),
                {"pg_schema": pg_schema, "table_name": table_name},
            ).fetchall()
        return len(rows)

    def test_migration_succeeds_for_legacy_table_with_multiple_combinations(self, engine, pg_schema):
        import sqlalchemy as sa  # noqa: PLC0415

        table_name = schema.ASSET_TABLE_SPECS["POSTE"].table_name
        qualified_table = f"{pg_schema}.{table_name}"

        self._create_legacy_table(engine, qualified_table)

        rows_to_insert = [
            ("ENEL_SP", "SUDESTE", "POSTE::1", -46.0, -23.0),
            ("ENEL_SP", "SUDESTE", "POSTE::2", -46.1, -23.1),
            ("CEMIG", "SUDESTE", "POSTE::3", -44.0, -19.0),
            ("CEMIG", "SUDESTE", "POSTE::4", -44.1, -19.1),
        ]
        for distribuidora, regiao, asset_key, lon, lat in rows_to_insert:
            self._insert_legacy_row(engine, qualified_table, distribuidora, regiao, asset_key, lon, lat)

        import sqlalchemy as sa  # noqa: PLC0415

        with engine.connect() as conn:
            original_rows = conn.execute(
                sa.text(
                    f"SELECT asset_key, distribuidora, regiao, ST_AsText(geometry) AS geom "
                    f"FROM {qualified_table} ORDER BY asset_key"
                )
            ).fetchall()
        original_by_key = {row.asset_key: row for row in original_rows}
        assert len(original_by_key) == 4

        schema.ensure_asset_table(engine, "POSTE", pg_schema)

        assert schema.is_partitioned(engine, pg_schema, table_name) is True

        with engine.connect() as conn:
            new_rows = conn.execute(
                sa.text(
                    f"SELECT asset_key, distribuidora, regiao, ST_AsText(geometry) AS geom "
                    f"FROM {qualified_table} ORDER BY asset_key"
                )
            ).fetchall()

        assert len(new_rows) == len(original_rows) == 4

        new_by_key = {row.asset_key: row for row in new_rows}
        assert set(new_by_key.keys()) == set(original_by_key.keys())
        for asset_key, original_row in original_by_key.items():
            new_row = new_by_key[asset_key]
            assert new_row.distribuidora == original_row.distribuidora
            assert new_row.regiao == original_row.regiao
            assert new_row.geom == original_row.geom

        assert self._count_child_partitions(engine, pg_schema, table_name) == 2

        import sqlalchemy as sa  # noqa: PLC0415

        with engine.connect() as conn:
            old_table_exists = conn.execute(
                sa.text(
                    "SELECT 1 FROM information_schema.tables "
                    "WHERE table_schema = :pg_schema AND table_name = :table_name"
                ),
                {"pg_schema": pg_schema, "table_name": f"{table_name}_old"},
            ).fetchone()
        assert old_table_exists is None, (
            f"Tabela '{pg_schema}.{table_name}_old' deveria ter sido dropada após a migração."
        )

    def test_ensure_asset_table_is_noop_when_already_partitioned(self, engine, pg_schema):
        table_name = schema.ASSET_TABLE_SPECS["POSTE"].table_name

        schema.ensure_asset_table(engine, "POSTE", pg_schema)
        assert schema.is_partitioned(engine, pg_schema, table_name) is True

        structure_after_first_call = _snapshot_table_structure(engine, pg_schema, table_name)

        schema.ensure_asset_table(engine, "POSTE", pg_schema)
        structure_after_second_call = _snapshot_table_structure(engine, pg_schema, table_name)

        assert structure_after_second_call == structure_after_first_call, (
            f"Estrutura de '{pg_schema}.{table_name}' mudou após a segunda chamada de "
            "ensure_asset_table numa tabela já particionada — deveria ser no-op."
        )

    def test_migration_aborted_when_partition_key_is_undefined(self, engine, pg_schema):
        import sqlalchemy as sa  # noqa: PLC0415

        table_name = schema.ASSET_TABLE_SPECS["POSTE"].table_name
        qualified_table = f"{pg_schema}.{table_name}"

        self._create_legacy_table(engine, qualified_table)

        self._insert_legacy_row(engine, qualified_table, "ENEL_SP", "SUDESTE", "POSTE::1", -46.0, -23.0)
        self._insert_legacy_row(engine, qualified_table, "CEMIG", "SUDESTE", "POSTE::2", -44.0, -19.0)
        self._insert_legacy_row(engine, qualified_table, "ENEL_SP", "", "POSTE::3", -46.2, -23.2)

        with pytest.raises(Exception) as exc_info:
            schema.ensure_asset_table(engine, "POSTE", pg_schema)

        message = str(exc_info.value)
        assert "1" in message, (
            f"A mensagem de erro deveria mencionar a quantidade exata (1) de Ativos "
            f"problemáticos, obtido: {message!r}"
        )
        assert table_name in message or qualified_table in message, (
            f"A mensagem de erro deveria identificar a tabela '{qualified_table}', "
            f"obtido: {message!r}"
        )

        assert schema.is_partitioned(engine, pg_schema, table_name) is False

        with engine.connect() as conn:
            remaining_count = conn.execute(
                sa.text(f"SELECT COUNT(*) FROM {qualified_table}")
            ).scalar_one()
        assert remaining_count == 3, (
            f"A tabela original deveria continuar com as 3 linhas originais intactas, "
            f"obtido {remaining_count}."
        )
