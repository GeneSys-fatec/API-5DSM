"""Testes unitários de extract.py — resolução de layers e fallback."""
from __future__ import annotations

import sys
import types
from pathlib import Path

import pandas as pd
import pytest

_ETL_DIR = Path(__file__).resolve().parent.parent
if str(_ETL_DIR) not in sys.path:
    sys.path.insert(0, str(_ETL_DIR))


def _ensure_fiona_stub() -> None:
    if "fiona" in sys.modules and getattr(sys.modules["fiona"], "_is_test_stub", False):
        return
    try:
        import fiona  # noqa: F401
    except ModuleNotFoundError:
        stub = types.ModuleType("fiona")
        stub._is_test_stub = True
        stub.listlayers = lambda gdb_path: []
        sys.modules["fiona"] = stub


_ensure_fiona_stub()

if "extract" in sys.modules:
    del sys.modules["extract"]
import extract  # noqa: E402


class TestResolveLayerSourceDirectMatch:
    def test_exact_name_match_returns_no_fallback_spec(self):
        result = extract._resolve_layer_source("SUB", ["SUB", "SSDBT"])
        assert result == ("SUB", None)

    def test_case_insensitive_match_returns_no_fallback_spec(self):
        result = extract._resolve_layer_source("SUB", ["sub", "SSDBT"])
        assert result == ("sub", None)


class TestResolveLayerSourcePosteFallback:
    def test_poste_missing_but_ponnot_present_resolves_to_ponnot_fallback(self):
        available = ["SUB", "PONNOT", "SSDBT", "SSDMT", "SSDAT"]
        result = extract._resolve_layer_source("POSTE", available)
        assert result is not None

        actual_layer, fallback_spec = result
        assert actual_layer == "PONNOT"
        assert fallback_spec == {
            "layer": "PONNOT",
            "filter_col": "TIP_PN",
            "filter_value": "POS",
        }

    def test_poste_missing_and_ponnot_also_missing_returns_none(self):
        available = ["SUB", "SSDBT", "SSDMT", "SSDAT"]
        result = extract._resolve_layer_source("POSTE", available)
        assert result is None

    def test_poste_present_directly_does_not_use_fallback(self):
        available = ["POSTE", "PONNOT", "SUB"]
        result = extract._resolve_layer_source("POSTE", available)
        assert result == ("POSTE", None)

    def test_layer_without_configured_fallback_returns_none_when_missing(self):
        available = ["SUB", "PONNOT"]
        result = extract._resolve_layer_source("UCBT", available)
        assert result is None


class TestSelectRelevantLayersIncludesPosteFallback:
    def test_poste_included_via_fallback_when_only_ponnot_available(self):
        available = ["SUB", "PONNOT", "SSDBT", "SSDMT", "SSDAT"]
        selected = extract.select_relevant_layers(available)
        assert "POSTE" in selected

    def test_ucbt_ucmt_still_absent_without_fallback(self):
        available = ["SUB", "PONNOT", "SSDBT", "SSDMT", "SSDAT"]
        selected = extract.select_relevant_layers(available)
        assert "UCBT" not in selected
        assert "UCMT" not in selected


class TestReadLayerAppliesPosteFallbackFilter:
    def test_read_layer_filters_ponnot_by_tip_pn_pos(self, monkeypatch):
        import geopandas as gpd
        from shapely.geometry import Point

        ponnot_gdf = gpd.GeoDataFrame(
            {
                "COD_ID": ["P1", "T1", "P2", "D1"],
                "TIP_PN": ["POS", "TOR", "POS", "DRV"],
                "geometry": [Point(0, 0), Point(1, 1), Point(2, 2), Point(3, 3)],
            },
            geometry="geometry",
            crs="EPSG:4674",
        )

        monkeypatch.setattr(extract.fiona, "listlayers", lambda gdb_path: ["SUB", "PONNOT"])
        monkeypatch.setattr(
            extract.gpd, "read_file",
            lambda gdb_path, layer: ponnot_gdf if layer == "PONNOT" else pd.DataFrame(),
        )

        result = extract.read_layer("/fake/path.gdb", "POSTE")

        assert len(result) == 2
        assert set(result["COD_ID"]) == {"P1", "P2"}
        assert set(result["TIP_PN"]) == {"POS"}

    def test_read_layer_raises_when_fallback_missing_filter_column(self, monkeypatch):
        import geopandas as gpd
        from shapely.geometry import Point

        ponnot_gdf_without_tip_pn = gpd.GeoDataFrame(
            {"COD_ID": ["P1"], "geometry": [Point(0, 0)]},
            geometry="geometry",
            crs="EPSG:4674",
        )

        monkeypatch.setattr(extract.fiona, "listlayers", lambda gdb_path: ["SUB", "PONNOT"])
        monkeypatch.setattr(
            extract.gpd, "read_file",
            lambda gdb_path, layer: ponnot_gdf_without_tip_pn,
        )

        with pytest.raises(RuntimeError, match="TIP_PN"):
            extract.read_layer("/fake/path.gdb", "POSTE")