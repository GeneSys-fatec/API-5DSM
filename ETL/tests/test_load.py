from __future__ import annotations

import sys
from pathlib import Path

import geopandas as gpd
import pandas as pd
import pytest
import sqlalchemy as sa
from shapely.geometry import Point

_ETL_DIR = Path(__file__).resolve().parent.parent
if str(_ETL_DIR) not in sys.path:
    sys.path.insert(0, str(_ETL_DIR))

import load  # noqa: E402
import schema  # noqa: E402
import transform  # noqa: E402


def _build_gdf(cod_id: str, dist_name: str, layer_name: str, regiao: str, x: float, y: float) -> gpd.GeoDataFrame:
    gdf = gpd.GeoDataFrame(
        {"COD_ID": [cod_id], "geometry": [Point(x, y)]},
        geometry="geometry",
        crs="EPSG:4326",
    )
    gdf = transform.add_stable_key(gdf, layer_name=layer_name, dist_name=dist_name, key_col="COD_ID")
    gdf["tipo_ativo"] = layer_name
    gdf["distribuidora"] = dist_name
    gdf["regiao"] = regiao
    return gdf


def _project_to_fixed_columns(gdf: gpd.GeoDataFrame) -> gpd.GeoDataFrame:
    return gdf[list(schema.FIXED_COLUMNS)].copy()


class TestProjectToFixedColumns:

    def test_removes_extra_columns_keeping_exactly_fixed_columns(self):
        gdf = gpd.GeoDataFrame(
            {
                "tipo_ativo": ["POSTE"],
                "distribuidora": ["ENEL_SP"],
                "regiao": ["SP"],
                "asset_key": ["POSTE::123"],
                "COD_ID_ORIGINAL": ["123"],
                "OUTRA_COLUNA_EXTRA": ["valor_qualquer"],
                "geometry": [Point(0, 0)],
            },
            geometry="geometry",
        )

        projected = _project_to_fixed_columns(gdf)

        assert list(projected.columns) == list(schema.FIXED_COLUMNS)
        assert "COD_ID_ORIGINAL" not in projected.columns
        assert "OUTRA_COLUNA_EXTRA" not in projected.columns

    def test_preserves_row_values_for_fixed_columns(self):
        gdf = gpd.GeoDataFrame(
            {
                "tipo_ativo": ["POSTE"],
                "distribuidora": ["ENEL_SP"],
                "regiao": ["SP"],
                "asset_key": ["POSTE::123"],
                "COD_ID_ORIGINAL": ["123"],
                "geometry": [Point(1, 2)],
            },
            geometry="geometry",
        )

        projected = _project_to_fixed_columns(gdf)

        assert projected.iloc[0]["tipo_ativo"] == "POSTE"
        assert projected.iloc[0]["distribuidora"] == "ENEL_SP"
        assert projected.iloc[0]["regiao"] == "SP"
        assert projected.iloc[0]["asset_key"] == "POSTE::123"
        assert projected.iloc[0]["geometry"] == Point(1, 2)

    def test_does_not_mutate_original_gdf(self):
        gdf = gpd.GeoDataFrame(
            {
                "tipo_ativo": ["POSTE"],
                "distribuidora": ["ENEL_SP"],
                "regiao": ["SP"],
                "asset_key": ["POSTE::123"],
                "COD_ID_ORIGINAL": ["123"],
                "geometry": [Point(0, 0)],
            },
            geometry="geometry",
        )

        _project_to_fixed_columns(gdf)

        assert "COD_ID_ORIGINAL" in gdf.columns



class TestValidPartitionKeyMask:

    def test_none_in_distribuidora_is_invalid(self):
        gdf = pd.DataFrame({"distribuidora": [None], "regiao": ["SP"]})

        mask = load._valid_partition_key_mask(gdf)

        assert mask.tolist() == [False]

    def test_none_in_regiao_is_invalid(self):
        gdf = pd.DataFrame({"distribuidora": ["ENEL_SP"], "regiao": [None]})

        mask = load._valid_partition_key_mask(gdf)

        assert mask.tolist() == [False]

    def test_empty_string_in_distribuidora_is_invalid(self):
        gdf = pd.DataFrame({"distribuidora": [""], "regiao": ["SP"]})

        mask = load._valid_partition_key_mask(gdf)

        assert mask.tolist() == [False]

    def test_empty_string_in_regiao_is_invalid(self):
        gdf = pd.DataFrame({"distribuidora": ["ENEL_SP"], "regiao": [""]})

        mask = load._valid_partition_key_mask(gdf)

        assert mask.tolist() == [False]

    def test_whitespace_only_in_distribuidora_is_invalid(self):
        gdf = pd.DataFrame({"distribuidora": ["   "], "regiao": ["SP"]})

        mask = load._valid_partition_key_mask(gdf)

        assert mask.tolist() == [False]

    def test_whitespace_only_in_regiao_is_invalid(self):
        gdf = pd.DataFrame({"distribuidora": ["ENEL_SP"], "regiao": ["   "]})

        mask = load._valid_partition_key_mask(gdf)

        assert mask.tolist() == [False]

    def test_valid_values_with_leading_trailing_spaces_remain_valid(self):
        gdf = pd.DataFrame({"distribuidora": [" CEMIG "], "regiao": [" SUDESTE "]})

        mask = load._valid_partition_key_mask(gdf)

        assert mask.tolist() == [True]

    def test_does_not_trim_valid_values(self):
        gdf = pd.DataFrame({"distribuidora": [" CEMIG "], "regiao": ["SUDESTE"]})

        mask = load._valid_partition_key_mask(gdf)

        assert mask.tolist() == [True]
        # a função não deve mutar os valores originais
        assert gdf.iloc[0]["distribuidora"] == " CEMIG "

    def test_mixed_batch_marks_only_invalid_rows(self):
        gdf = pd.DataFrame(
            {
                "distribuidora": ["ENEL_SP", None, "CEMIG", "", "COPEL"],
                "regiao": ["SP", "SUDESTE", "   ", "SUDESTE", "SUL"],
            }
        )

        mask = load._valid_partition_key_mask(gdf)

        assert mask.tolist() == [True, False, False, False, True]

    def test_does_not_mutate_original_gdf(self):
        gdf = pd.DataFrame({"distribuidora": [None, "ENEL_SP"], "regiao": ["SP", None]})
        original_distribuidora = gdf["distribuidora"].copy()
        original_regiao = gdf["regiao"].copy()

        load._valid_partition_key_mask(gdf)

        pd.testing.assert_series_equal(gdf["distribuidora"], original_distribuidora)
        pd.testing.assert_series_equal(gdf["regiao"], original_regiao)


class TestLogRejectedRows:

    def test_logs_distribuidora_when_null(self, caplog):
        invalid_rows = pd.DataFrame({"distribuidora": [None], "regiao": ["SP"]})

        with caplog.at_level("ERROR"):
            load._log_rejected_rows("poste", invalid_rows)

        assert len(caplog.records) == 1
        message = caplog.records[0].getMessage()
        assert "poste" in message
        assert "distribuidora" in message
        assert "regiao" not in message

    def test_logs_regiao_when_empty_string(self, caplog):
        invalid_rows = pd.DataFrame({"distribuidora": ["ENEL_SP"], "regiao": [""]})

        with caplog.at_level("ERROR"):
            load._log_rejected_rows("sub", invalid_rows)

        assert len(caplog.records) == 1
        message = caplog.records[0].getMessage()
        assert "sub" in message
        assert "regiao" in message
        assert "distribuidora" not in message

    def test_logs_both_columns_when_whitespace_only(self, caplog):
        invalid_rows = pd.DataFrame({"distribuidora": ["   "], "regiao": ["   "]})

        with caplog.at_level("ERROR"):
            load._log_rejected_rows("ucbt", invalid_rows)

        assert len(caplog.records) == 1
        message = caplog.records[0].getMessage()
        assert "ucbt" in message
        assert "distribuidora" in message
        assert "regiao" in message

    def test_logs_one_message_per_invalid_row(self, caplog):
        invalid_rows = pd.DataFrame(
            {
                "distribuidora": [None, "CEMIG"],
                "regiao": ["SP", ""],
            }
        )

        with caplog.at_level("ERROR"):
            load._log_rejected_rows("poste", invalid_rows)

        assert len(caplog.records) == 2

    def test_does_not_raise_and_does_not_mutate(self, caplog):
        invalid_rows = pd.DataFrame({"distribuidora": [None], "regiao": [""]})
        original = invalid_rows.copy()

        with caplog.at_level("ERROR"):
            load._log_rejected_rows("poste", invalid_rows)

        pd.testing.assert_frame_equal(invalid_rows, original)


class TestUpsertLayerRejectsInvalidRowsWithinBatch:

    def test_invalid_row_is_rejected_and_logged_while_valid_rows_are_inserted(
        self, engine, pg_schema, caplog
    ):
        gdf_valid = _build_gdf(
            cod_id="1", dist_name="CEMIG", layer_name="POSTE", regiao="SUDESTE",
            x=-43.9, y=-19.9,
        )
        gdf_invalid = _build_gdf(
            cod_id="2", dist_name="CEMIG", layer_name="POSTE", regiao="",
            x=-44.0, y=-20.0,
        )
        gdf = pd.concat([gdf_valid, gdf_invalid], ignore_index=True)
        gdf = gpd.GeoDataFrame(gdf, geometry="geometry", crs="EPSG:4326")

        with caplog.at_level("ERROR"):
            total_processed = load.upsert_layer(
                gdf, layer_name="POSTE", key_col="COD_ID", engine=engine, pg_schema=pg_schema
            )

        assert total_processed == 1

        rejected_messages = [
            record.getMessage()
            for record in caplog.records
            if "rejeitada" in record.getMessage()
        ]
        assert len(rejected_messages) == 1
        assert "regiao" in rejected_messages[0]

        with engine.connect() as conn:
            rows = conn.execute(
                sa.text(f"SELECT asset_key, regiao FROM {pg_schema}.poste")
            ).fetchall()

        assert len(rows) == 1
        assert rows[0].asset_key == "POSTE::CEMIG::1"
        assert rows[0].regiao == "SUDESTE"


class TestUpsertLayerCrossPartitionConflict:

    def test_same_asset_key_in_different_partition_raises_and_preserves_original(
        self, engine, pg_schema
    ):
        gdf_original = _build_gdf(
            cod_id="999", dist_name="DIST_A", layer_name="POSTE", regiao="REGIAO_1",
            x=-43.9, y=-19.9,
        )
        load.upsert_layer(
            gdf_original, layer_name="POSTE", key_col="COD_ID", engine=engine, pg_schema=pg_schema
        )

        # Mesma asset_key (POSTE::DIST_A::999), partição diferente (regiao muda)
        gdf_conflicting = _build_gdf(
            cod_id="999", dist_name="DIST_A", layer_name="POSTE", regiao="REGIAO_2",
            x=-44.5, y=-20.5,
        )

        with pytest.raises(ValueError) as exc_info:
            load.upsert_layer(
                gdf_conflicting, layer_name="POSTE", key_col="COD_ID", engine=engine, pg_schema=pg_schema
            )

        message = str(exc_info.value)
        assert "POSTE::DIST_A::999" in message
        assert "DIST_A::REGIAO_1" in message
        assert "DIST_A::REGIAO_2" in message

        with engine.connect() as conn:
            rows = conn.execute(
                sa.text(
                    f"SELECT regiao, ST_AsText(geometry) AS geom FROM {pg_schema}.poste"
                )
            ).fetchall()

        assert len(rows) == 1, "O registro original não deveria ter sido duplicado nem removido."
        assert rows[0].regiao == "REGIAO_1", "O registro original não deveria ter sido alterado."
