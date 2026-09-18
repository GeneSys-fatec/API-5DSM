from __future__ import annotations

import sys
from pathlib import Path

import geopandas as gpd
import pytest
from shapely.geometry import Point

_ETL_DIR = Path(__file__).resolve().parent.parent
if str(_ETL_DIR) not in sys.path:
    sys.path.insert(0, str(_ETL_DIR))

import transform  # noqa: E402


def _make_gdf(cod_id: str, x: float, y: float) -> gpd.GeoDataFrame:
    return gpd.GeoDataFrame(
        {"COD_ID": [cod_id], "geometry": [Point(x, y)]},
        geometry="geometry",
        crs="EPSG:4326",
    )


class TestAddStableKey:

    def test_asset_key_format_includes_layer_distribuidora_and_cod_id(self):
        gdf = _make_gdf(cod_id="123", x=-43.94, y=-19.92)

        result = transform.add_stable_key(gdf, layer_name="POSTE", dist_name="CEMIG", key_col="COD_ID")

        assert result["asset_key"].iloc[0] == "POSTE::CEMIG::123"

    def test_same_cod_id_different_distribuidora_yields_different_asset_key(self):
        gdf_cemig = _make_gdf(cod_id="123", x=-43.94, y=-19.92)
        gdf_enel = _make_gdf(cod_id="123", x=-46.63, y=-23.55)

        result_cemig = transform.add_stable_key(gdf_cemig, layer_name="POSTE", dist_name="CEMIG", key_col="COD_ID")
        result_enel = transform.add_stable_key(gdf_enel, layer_name="POSTE", dist_name="ENEL_SP", key_col="COD_ID")

        asset_key_cemig = result_cemig["asset_key"].iloc[0]
        asset_key_enel = result_enel["asset_key"].iloc[0]

        assert asset_key_cemig == "POSTE::CEMIG::123"
        assert asset_key_enel == "POSTE::ENEL_SP::123"
        assert asset_key_cemig != asset_key_enel

    def test_missing_key_col_raises_key_error(self):
        gdf = gpd.GeoDataFrame({"geometry": [Point(0, 0)]}, geometry="geometry", crs="EPSG:4326")

        with pytest.raises(KeyError):
            transform.add_stable_key(gdf, layer_name="POSTE", dist_name="CEMIG", key_col="COD_ID")

    def test_does_not_mutate_original_gdf(self):
        gdf = _make_gdf(cod_id="123", x=0, y=0)

        transform.add_stable_key(gdf, layer_name="POSTE", dist_name="CEMIG", key_col="COD_ID")

        assert "asset_key" not in gdf.columns


class TestPrepareLayerAssetKeyIntegration:

    def test_prepare_layer_generates_distribuidora_aware_asset_key(self):
        gdf = _make_gdf(cod_id="456", x=-43.9, y=-19.9)

        result = transform.prepare_layer(
            gdf,
            layer_name="POSTE",
            dist_name="ENEL_SP",
            key_col="COD_ID",
            target_crs="EPSG:4326",
            source_crs_fallback="EPSG:4674",
        )

        assert result["asset_key"].iloc[0] == "POSTE::ENEL_SP::456"

    def test_prepare_layer_two_distribuidoras_same_cod_id_no_collision(self):
        gdf_a = _make_gdf(cod_id="789", x=-43.9, y=-19.9)
        gdf_b = _make_gdf(cod_id="789", x=-46.6, y=-23.5)

        result_a = transform.prepare_layer(
            gdf_a,
            layer_name="POSTE",
            dist_name="CEMIG",
            key_col="COD_ID",
            target_crs="EPSG:4326",
            source_crs_fallback="EPSG:4674",
        )
        result_b = transform.prepare_layer(
            gdf_b,
            layer_name="POSTE",
            dist_name="ENEL_SP",
            key_col="COD_ID",
            target_crs="EPSG:4326",
            source_crs_fallback="EPSG:4674",
        )

        assert result_a["asset_key"].iloc[0] != result_b["asset_key"].iloc[0]
