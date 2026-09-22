"""
test_geometry_fix.py — Testes unitários para validação e correção de geometrias em transform.py.
"""
import sys
from pathlib import Path

# Garante que o diretório pai (ETL/) esteja no path do Python
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import unittest
import geopandas as gpd
from shapely.geometry import Point, LineString, Polygon

import transform



class TestGeometryFix(unittest.TestCase):

    def test_fix_geometry_valid_geometries(self):
        """Garante que geometrias válidas não são alteradas ou removidas."""
        gdf = gpd.GeoDataFrame(
            {"COD_ID": [1, 2, 3]},
            geometry=[
                Point(0, 0),
                LineString([(0, 0), (1, 1)]),
                Polygon([(0, 0), (0, 1), (1, 1), (1, 0), (0, 0)]),
            ],
            crs="EPSG:4326",
        )
        res = transform.fix_geometry(gdf)
        self.assertEqual(len(res), 3)
        self.assertTrue(res.geometry.is_valid.all())

    def test_fix_geometry_null_and_empty(self):
        """Garante que feições com geometria nula (None) e vazia (EMPTY) são descartadas."""
        gdf = gpd.GeoDataFrame(
            {"COD_ID": [1, 2, 3, 4]},
            geometry=[
                Point(0, 0),
                None,
                Polygon(),  # Polygon EMPTY
                Point(),    # Point EMPTY
            ],
            crs="EPSG:4326",
        )
        res = transform.fix_geometry(gdf)
        self.assertEqual(len(res), 1)
        self.assertEqual(res.iloc[0]["COD_ID"], 1)

    def test_fix_geometry_self_intersection(self):
        """Garante que geometrias com auto-interseção (laço em 8) são reparadas."""
        # Polígono em formato de borboleta (inválido por auto-interseção em (1, 1))
        invalid_poly = Polygon([(0, 0), (0, 2), (2, 0), (2, 2), (0, 0)])
        self.assertFalse(invalid_poly.is_valid)

        gdf = gpd.GeoDataFrame(
            {"COD_ID": [1, 2]},
            geometry=[
                Point(1, 1),
                invalid_poly,
            ],
            crs="EPSG:4326",
        )

        res = transform.fix_geometry(gdf)
        self.assertEqual(len(res), 2)
        self.assertTrue(res.geometry.is_valid.all())

    def test_prepare_layer_pipeline(self):
        """Testa a integração do pipeline prepare_layer com geometrias defeituosas."""
        invalid_poly = Polygon([(0, 0), (0, 2), (2, 0), (2, 2), (0, 0)])
        gdf = gpd.GeoDataFrame(
            {"COD_ID": ["P1", "P1", "P2", "P3"]},  # P1 duplicado
            geometry=[
                Point(0, 0),
                Point(0, 0),
                invalid_poly,
                None,  # nulo
            ],
            crs="EPSG:4674",
        )

        res = transform.prepare_layer(
            gdf,
            layer_name="POSTE",
            key_col="COD_ID",
            target_crs="EPSG:4326",
            source_crs_fallback="EPSG:4674",
        )

        # Esperado: P1 deduplicado (1), P2 corrigido (1), P3 descartado (0) -> 2 feições
        self.assertEqual(len(res), 2)
        self.assertEqual(set(res["COD_ID"]), {"P1", "P2"})
        self.assertTrue(res.geometry.is_valid.all())
        self.assertIn("asset_key", res.columns)


if __name__ == "__main__":
    unittest.main()

