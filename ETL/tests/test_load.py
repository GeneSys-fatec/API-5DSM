from __future__ import annotations

import sys
from pathlib import Path

import geopandas as gpd
import pandas as pd
from shapely.geometry import Point

_ETL_DIR = Path(__file__).resolve().parent.parent
if str(_ETL_DIR) not in sys.path:
    sys.path.insert(0, str(_ETL_DIR))

import schema  # noqa: E402


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
