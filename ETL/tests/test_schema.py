from __future__ import annotations

import sys
from pathlib import Path

import pytest

_ETL_DIR = Path(__file__).resolve().parent.parent
if str(_ETL_DIR) not in sys.path:
    sys.path.insert(0, str(_ETL_DIR))

import schema  # noqa: E402


def _extract_top_level_column_names(create_table_stmt: str) -> list[str]:
    body = create_table_stmt.split("(", 1)[1].rsplit(")", 1)[0]
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


class TestGetSpec:
    """Testes unitÃ¡rios de `schema.get_spec`. Validates: Requirements 1.1, 7.1."""

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
    """Testes unitÃ¡rios de `schema.ASSET_TABLE_SPECS`. Validates: Requirements 7.1, 7.2, 7.3, 7.4, 7.5."""

    def test_contains_exactly_the_five_expected_layers(self):
        expected_layers = {"POSTE", "SUB", "UCBT", "UCMT", "SSDMT"}

        assert set(schema.ASSET_TABLE_SPECS.keys()) == expected_layers

    def test_each_spec_key_matches_its_own_layer_field(self):
        for layer_name, spec in schema.ASSET_TABLE_SPECS.items():
            assert spec.layer == layer_name


class TestDdlForLayerPoste:
    """Testes unitÃ¡rios de `schema.ddl_for_layer("POSTE", ...)`.
    Validates: Requirements 2.1, 2.2, 3.1, 3.2, 3.5, 4.1, 5.1."""

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


class TestDdlForLayerSub:
    """Testes unitÃ¡rios de `schema.ddl_for_layer("SUB", ...)`.
    Validates: Requirements 2.1, 2.3, 3.3, 3.4, 3.5, 4.1, 5.1."""

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


class TestDdlForLayerAllLayers:
    """Testes unitÃ¡rios de `schema.ddl_for_layer` para as 5 layers de
    `ASSET_TABLE_SPECS`: colunas exatas e nomes de Ã­ndices.
    Validates: Requirements 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 5.1."""

    EXPECTED_COLUMNS = ["id", "tipo_ativo", "distribuidora", "regiao", "asset_key", "geometry"]

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
        assert f"ON bdgd.{table} (asset_key)" in unique_index

        assert f"CREATE INDEX IF NOT EXISTS idx_{table}_geometry" in gist_index
        assert f"ON bdgd.{table} USING GIST (geometry)" in gist_index


class TestEnsureAssetTableIntegration:
    """Testes de integraÃ§Ã£o de `schema.ensure_asset_table` contra PostGIS real.

    Requerem um Postgres/PostGIS acessÃ­vel via `BDGD_DB_URL` (fixtures
    `engine`/`pg_schema` de `conftest.py`). Se o banco nÃ£o estiver disponÃ­vel,
    a fixture `engine` pula (skip) estes testes automaticamente â€” nenhum
    banco Ã© iniciado por este mÃ³dulo.

    Validates: Requirements 1.1, 1.2, 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4, 3.5.
    """

    # Coluna â†’ (data_type, is_nullable[, udt_name]) esperados em
    # information_schema.columns. `data_type` de colunas de geometria do
    # PostGIS Ã© sempre "USER-DEFINED" (tipo definido pela extensÃ£o), com o
    # tipo real exposto em `udt_name`.
    EXPECTED_COLUMNS = {
        "id": {"data_type": "bigint", "is_nullable": "NO"},
        "tipo_ativo": {"data_type": "text", "is_nullable": "NO"},
        "distribuidora": {"data_type": "text", "is_nullable": "NO"},
        "regiao": {"data_type": "text", "is_nullable": "NO"},
        "asset_key": {"data_type": "text", "is_nullable": "NO"},
        "geometry": {"data_type": "USER-DEFINED", "is_nullable": "NO", "udt_name": "geometry"},
    }

    @pytest.mark.parametrize("layer_name", list(schema.ASSET_TABLE_SPECS.keys()))
    def test_ensure_asset_table_creates_table_with_expected_columns(self, engine, pg_schema, layer_name):
        import sqlalchemy as sa  # noqa: PLC0415 (import tardio, sÃ³ necessÃ¡rio aqui)

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

        # Exatamente as colunas esperadas â€” nem mais, nem menos.
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
    """Captura um snapshot da estrutura de uma tabela: colunas, Ã­ndices e
    constraints (incluindo CHECK), para comparaÃ§Ã£o de idempotÃªncia.

    Usa `pg_catalog.pg_constraint`/`pg_get_constraintdef` para constraints
    (PK, UNIQUE, CHECK, ...) e `pg_indexes` para a definiÃ§Ã£o textual completa
    de cada Ã­ndice â€” ambos refletem fielmente qualquer alteraÃ§Ã£o estrutural,
    nÃ£o apenas presenÃ§a/ausÃªncia de nomes.
    """
    import sqlalchemy as sa  # noqa: PLC0415 (import tardio, sÃ³ necessÃ¡rio aqui)

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
    """Teste de integraÃ§Ã£o de idempotÃªncia de `schema.ensure_asset_table`.

    Property 1: Idempotent and deterministic DDL structure.

    Para cada uma das 5 layers, chama `ensure_asset_table` duas vezes em
    sequÃªncia e verifica que a segunda chamada nÃ£o levanta erro e que a
    estrutura resultante (colunas, Ã­ndices, constraints) Ã© idÃªntica Ã  da
    primeira chamada.

    Validates: Requirements 1.3, 6.3, 6.4.
    """

    @pytest.mark.parametrize("layer_name", list(schema.ASSET_TABLE_SPECS.keys()))
    def test_second_call_is_noop_and_structure_is_identical(self, engine, pg_schema, layer_name):
        table_name = schema.ASSET_TABLE_SPECS[layer_name].table_name

        # Primeira chamada: cria a tabela, Ã­ndices e constraints.
        schema.ensure_asset_table(engine, layer_name, pg_schema)
        structure_after_first_call = _snapshot_table_structure(engine, pg_schema, table_name)

        # Segunda chamada: nÃ£o deve levantar erro (idempotÃªncia via IF NOT EXISTS).
        schema.ensure_asset_table(engine, layer_name, pg_schema)
        structure_after_second_call = _snapshot_table_structure(engine, pg_schema, table_name)

        assert structure_after_second_call == structure_after_first_call, (
            f"Estrutura de '{pg_schema}.{table_name}' mudou apÃ³s a segunda chamada de "
            f"ensure_asset_table para a layer {layer_name!r}."
        )


class TestAssetKeyUniqueIndexSupportsOnConflict:
    """Teste de integraÃ§Ã£o: o Ã­ndice Ãºnico em `asset_key` suporta `ON CONFLICT
    (asset_key) DO UPDATE`, resultando em 1 linha (update) ao inserir a mesma
    `asset_key` duas vezes, em vez de 2 linhas.

    Validates: Requirements 4.1, 4.2, 5.1, 5.2, 5.3.
    """

    def test_on_conflict_asset_key_upserts_single_row(self, engine, pg_schema):
        import sqlalchemy as sa  # noqa: PLC0415 (import tardio, sÃ³ necessÃ¡rio aqui)

        schema.ensure_asset_table(engine, "POSTE", pg_schema)
        table_name = schema.ASSET_TABLE_SPECS["POSTE"].table_name
        qualified_table = f"{pg_schema}.{table_name}"

        insert_sql = sa.text(
            f"""
            INSERT INTO {qualified_table} (tipo_ativo, distribuidora, regiao, asset_key, geometry)
            VALUES (
                :tipo_ativo, :distribuidora, :regiao, :asset_key,
                ST_SetSRID(ST_MakePoint(:lon, :lat), {schema.SRID})
            )
            ON CONFLICT (asset_key) DO UPDATE SET
                tipo_ativo = EXCLUDED.tipo_ativo,
                distribuidora = EXCLUDED.distribuidora,
                regiao = EXCLUDED.regiao,
                geometry = EXCLUDED.geometry
            """
        )

        with engine.begin() as conn:
            # Primeira inserÃ§Ã£o da asset_key.
            conn.execute(
                insert_sql,
                {
                    "tipo_ativo": "POSTE",
                    "distribuidora": "DIST_A",
                    "regiao": "REGIAO_1",
                    "asset_key": "POSTE::123",
                    "lon": -46.0,
                    "lat": -23.0,
                },
            )
            # Segunda inserÃ§Ã£o com a MESMA asset_key, valores diferentes â€”
            # deve resultar em UPDATE da linha existente, nÃ£o numa nova linha.
            conn.execute(
                insert_sql,
                {
                    "tipo_ativo": "POSTE",
                    "distribuidora": "DIST_B",
                    "regiao": "REGIAO_2",
                    "asset_key": "POSTE::123",
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
            f"Esperado exatamente 1 linha para asset_key='POSTE::123' apÃ³s dois "
            f"INSERT ... ON CONFLICT, obtido {len(rows)}."
        )
        assert rows[0].distribuidora == "DIST_B"
        assert rows[0].regiao == "REGIAO_2"


class TestGeometryGistIndexExistsInPgIndexes:
    """Teste de integraÃ§Ã£o: o Ã­ndice espacial `idx_<tabela>_geometry` existe
    em `pg_indexes` e usa o mÃ©todo de acesso GiST, para cada uma das 5 layers.

    Validates: Requirements 4.1, 4.2.
    """

    @pytest.mark.parametrize("layer_name", list(schema.ASSET_TABLE_SPECS.keys()))
    def test_idx_geometry_exists_and_uses_gist(self, engine, pg_schema, layer_name):
        import sqlalchemy as sa  # noqa: PLC0415 (import tardio, sÃ³ necessÃ¡rio aqui)

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
            f"Ãndice '{index_name}' nÃ£o encontrado em pg_indexes para "
            f"'{pg_schema}.{table_name}'."
        )
        assert "gist" in row.indexdef.lower(), (
            f"Ãndice '{index_name}' encontrado, mas indexdef nÃ£o usa GiST: {row.indexdef!r}"
        )


class TestSubGeometryCheckConstraint:
    """Teste de integraÃ§Ã£o: `CHECK` de subtipo de geometria em `bdgd.sub`.

    Insere um `POINT` e um `POLYGON` (ambos aceitos pelo CHECK) e depois
    tenta inserir uma `LINESTRING`, que deve ser rejeitada pelo
    `chk_sub_geometry_subtype`.

    Validates: Requirements 2.3.
    """

    def _insert_sub(self, engine, qualified_table: str, asset_key: str, wkt: str) -> None:
        import sqlalchemy as sa  # noqa: PLC0415 (import tardio, sÃ³ necessÃ¡rio aqui)

        insert_sql = sa.text(
            f"""
            INSERT INTO {qualified_table} (tipo_ativo, distribuidora, regiao, asset_key, geometry)
            VALUES (
                :tipo_ativo, :distribuidora, :regiao, :asset_key,
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
                    "wkt": wkt,
                },
            )

    def test_point_and_polygon_accepted_linestring_rejected(self, engine, pg_schema):
        import sqlalchemy as sa  # noqa: PLC0415 (import tardio, sÃ³ necessÃ¡rio aqui)

        schema.ensure_asset_table(engine, "SUB", pg_schema)
        table_name = schema.ASSET_TABLE_SPECS["SUB"].table_name
        qualified_table = f"{pg_schema}.{table_name}"

        # POINT â€” aceito pelo CHECK.
        self._insert_sub(engine, qualified_table, "SUB::POINT_1", "POINT(-46.0 -23.0)")

        # POLYGON â€” aceito pelo CHECK.
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

        # LINESTRING â€” rejeitada pelo CHECK chk_sub_geometry_subtype.
        with pytest.raises(sa.exc.IntegrityError):
            self._insert_sub(
                engine,
                qualified_table,
                "SUB::LINESTRING_1",
                "LINESTRING(-46.0 -23.0, -46.1 -23.1)",
            )

        # A transaÃ§Ã£o da inserÃ§Ã£o rejeitada jÃ¡ foi revertida (engine.begin()
        # do helper faz rollback automÃ¡tico em caso de exceÃ§Ã£o); confirma que
        # a tabela continua com apenas as 2 linhas vÃ¡lidas.
        with engine.connect() as conn:
            count_after_failed_insert = conn.execute(
                sa.text(f"SELECT COUNT(*) FROM {qualified_table}")
            ).scalar_one()
        assert count_after_failed_insert == 2


class TestEnsureAllAssetTablesSubset:
    """Teste de integraÃ§Ã£o: `ensure_all_asset_tables` com um subconjunto de
    layers cria apenas as tabelas correspondentes, sem tocar nas demais.

    Validates: Requirements 6.2, 7.1.
    """

    def test_only_requested_layer_table_is_created(self, engine, pg_schema):
        import sqlalchemy as sa  # noqa: PLC0415 (import tardio, sÃ³ necessÃ¡rio aqui)

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
