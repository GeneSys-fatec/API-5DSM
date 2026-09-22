from __future__ import annotations

import sys
from pathlib import Path

import geopandas as gpd
import pytest
import sqlalchemy as sa
from shapely.geometry import Point

_ETL_DIR = Path(__file__).resolve().parent.parent
if str(_ETL_DIR) not in sys.path:
    sys.path.insert(0, str(_ETL_DIR))

import load  # noqa: E402
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


class TestUpsertLayerIdempotency:

    def test_reimporting_same_asset_does_not_duplicate(self, engine, pg_schema):
        gdf = _build_gdf(cod_id="123", dist_name="CEMIG", layer_name="POSTE", regiao="SUDESTE", x=-43.94, y=-19.92)

        rows_first = load.upsert_layer(gdf.copy(), layer_name="POSTE", key_col="COD_ID", engine=engine, pg_schema=pg_schema)

        rows_second = load.upsert_layer(gdf.copy(), layer_name="POSTE", key_col="COD_ID", engine=engine, pg_schema=pg_schema)

        assert rows_first == 1
        assert rows_second == 1

        with engine.connect() as conn:
            count = conn.execute(
                sa.text(f"SELECT COUNT(*) FROM {pg_schema}.poste")
            ).scalar_one()

        assert count == 1, (
            f"Esperava exatamente 1 linha após duas importações do mesmo ativo, "
            f"obtive {count} — indica duplicação."
        )

    def test_reimporting_with_different_regiao_raises_cross_partition_conflict_error(self, engine, pg_schema):
        # Com a checagem de conflito cross-partição de asset_key implementada
        # (task 7.4, Requisito 2.3), reimportar o mesmo asset_key trocando
        # 'regiao' (que muda a Chave_de_Particionamento) não é mais tratado
        # como update in-place: é rejeitado com ValueError, e o registro
        # original permanece inalterado na partição original.
        gdf_v1 = _build_gdf(cod_id="456", dist_name="CEMIG", layer_name="POSTE", regiao="SUDESTE", x=-43.9, y=-19.9)
        load.upsert_layer(gdf_v1, layer_name="POSTE", key_col="COD_ID", engine=engine, pg_schema=pg_schema)

        gdf_v2 = _build_gdf(cod_id="456", dist_name="CEMIG", layer_name="POSTE", regiao="SUL", x=-44.5, y=-20.5)

        with pytest.raises(ValueError) as exc_info:
            load.upsert_layer(gdf_v2, layer_name="POSTE", key_col="COD_ID", engine=engine, pg_schema=pg_schema)

        message = str(exc_info.value)
        assert "POSTE::CEMIG::456" in message
        assert "CEMIG::SUDESTE" in message
        assert "CEMIG::SUL" in message

        with engine.connect() as conn:
            rows = conn.execute(
                sa.text(f"SELECT regiao, ST_AsText(geometry) AS geom FROM {pg_schema}.poste")
            ).fetchall()

        assert len(rows) == 1, "Esperava 1 linha (registro original inalterado), não uma linha nova."
        assert rows[0].regiao == "SUDESTE", "O registro original (v1) não deveria ter sido alterado."


class TestUpsertLayerDistinguishesDistribuidoras:

    def test_same_cod_id_different_distribuidora_creates_two_rows(self, engine, pg_schema):
        gdf_cemig = _build_gdf(cod_id="789", dist_name="CEMIG", layer_name="POSTE", regiao="SUDESTE", x=-43.94, y=-19.92)
        gdf_enel = _build_gdf(cod_id="789", dist_name="ENEL_SP", layer_name="POSTE", regiao="SUDESTE", x=-46.63, y=-23.55)

        load.upsert_layer(gdf_cemig, layer_name="POSTE", key_col="COD_ID", engine=engine, pg_schema=pg_schema)
        load.upsert_layer(gdf_enel, layer_name="POSTE", key_col="COD_ID", engine=engine, pg_schema=pg_schema)

        with engine.connect() as conn:
            rows = conn.execute(
                sa.text(f"SELECT distribuidora, asset_key FROM {pg_schema}.poste ORDER BY distribuidora")
            ).fetchall()

        assert len(rows) == 2, (
            f"Esperava 2 linhas (um ativo por distribuidora, mesmo COD_ID original), "
            f"obtive {len(rows)} — indica que um ativo sobrescreveu o outro."
        )
        distribuidoras = {row.distribuidora for row in rows}
        assert distribuidoras == {"CEMIG", "ENEL_SP"}

        asset_keys = {row.asset_key for row in rows}
        assert asset_keys == {"POSTE::CEMIG::789", "POSTE::ENEL_SP::789"}
