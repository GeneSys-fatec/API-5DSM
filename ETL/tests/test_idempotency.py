"""
test_idempotency.py — Testes de integração de idempotência (SYS-20).

Testes de integração (requerem PostGIS real, fixtures `engine`/`pg_schema`
de conftest.py): validam, através de `load.upsert_layer` de ponta a ponta
(não SQL escrito à mão), que:

1. Reimportar o mesmo GeoDataFrame (mesma BDGD) não duplica registros —
   a segunda chamada de `upsert_layer` deve atualizar, não inserir de novo.
2. Reimportar com dados atualizados (mesmo asset_key, valores diferentes)
   resulta na atualização da linha existente, não numa linha nova.
3. Dois ativos de distribuidoras diferentes com o mesmo COD_ID original
   NÃO colidem — cenário do bug corrigido em transform.add_stable_key
   (a asset_key agora inclui a distribuidora: "<LAYER>::<DIST>::<COD_ID>").
   Sem essa correção, o segundo upsert sobrescreveria o primeiro ativo.

Se nenhum Postgres/PostGIS estiver acessível via BDGD_DB_URL, estes testes
são pulados (skip) automaticamente pela fixture `engine` — nenhum banco é
iniciado por este módulo.
"""
from __future__ import annotations

import sys
from pathlib import Path

import geopandas as gpd
import sqlalchemy as sa
from shapely.geometry import Point

_ETL_DIR = Path(__file__).resolve().parent.parent
if str(_ETL_DIR) not in sys.path:
    sys.path.insert(0, str(_ETL_DIR))

import load  # noqa: E402
import transform  # noqa: E402


def _build_gdf(cod_id: str, dist_name: str, layer_name: str, regiao: str, x: float, y: float) -> gpd.GeoDataFrame:
    """Monta um GeoDataFrame "pronto para carga", passando pelo mesmo
    caminho de transform.add_stable_key usado pelo pipeline real (não
    escreve a asset_key à mão), para que o teste reflita o comportamento
    de produção fielmente.
    """
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
    """Reimportar a mesma BDGD (mesmo ativo) via load.upsert_layer não
    duplica registros — a segunda chamada atualiza a linha existente.

    Validates: critério de aceite da SYS-20 ("reimportar a mesma BDGD deve
    atualizar pela chave estável do ativo, nunca duplicar registros").
    """

    def test_reimporting_same_asset_does_not_duplicate(self, engine, pg_schema):
        gdf = _build_gdf(cod_id="123", dist_name="CEMIG", layer_name="POSTE", regiao="SUDESTE", x=-43.94, y=-19.92)

        # 1ª "importação" — simula a primeira execução do pipeline.
        rows_first = load.upsert_layer(gdf.copy(), layer_name="POSTE", key_col="COD_ID", engine=engine, pg_schema=pg_schema)

        # 2ª "importação" — simula reimportar o MESMO arquivo BDGD sem nenhuma
        # mudança (ex.: rodar o pipeline de novo por engano, ou re-agendado).
        rows_second = load.upsert_layer(gdf.copy(), layer_name="POSTE", key_col="COD_ID", engine=engine, pg_schema=pg_schema)

        assert rows_first == 1
        assert rows_second == 1  # upsert_layer reporta 1 feição processada, não erro

        with engine.connect() as conn:
            count = conn.execute(
                sa.text(f"SELECT COUNT(*) FROM {pg_schema}.poste")
            ).scalar_one()

        assert count == 1, (
            f"Esperava exatamente 1 linha após duas importações do mesmo ativo, "
            f"obtive {count} — indica duplicação."
        )

    def test_reimporting_with_updated_data_updates_existing_row_not_insert(self, engine, pg_schema):
        """Reimportar o mesmo ativo com dados atualizados (ex.: BDGD nova
        publicação, região mudou) deve atualizar a linha existente — a
        asset_key (chave estável) é o que identifica "é o mesmo ativo",
        não o conteúdo das outras colunas.
        """
        gdf_v1 = _build_gdf(cod_id="456", dist_name="CEMIG", layer_name="POSTE", regiao="SUDESTE", x=-43.9, y=-19.9)
        load.upsert_layer(gdf_v1, layer_name="POSTE", key_col="COD_ID", engine=engine, pg_schema=pg_schema)

        # Mesma asset_key (mesmo COD_ID + mesma distribuidora + mesma layer),
        # mas geometria e região diferentes — simula uma nova publicação da
        # BDGD com dados atualizados para o mesmo ativo físico.
        gdf_v2 = _build_gdf(cod_id="456", dist_name="CEMIG", layer_name="POSTE", regiao="SUL", x=-44.5, y=-20.5)
        load.upsert_layer(gdf_v2, layer_name="POSTE", key_col="COD_ID", engine=engine, pg_schema=pg_schema)

        with engine.connect() as conn:
            rows = conn.execute(
                sa.text(f"SELECT regiao, ST_AsText(geometry) AS geom FROM {pg_schema}.poste")
            ).fetchall()

        assert len(rows) == 1, "Esperava 1 linha (update), não uma linha nova."
        assert rows[0].regiao == "SUL", "A linha deveria refletir os dados da reimportação (v2), não da v1."


class TestUpsertLayerDistinguishesDistribuidoras:
    """Dois ativos de distribuidoras diferentes com o mesmo COD_ID original
    NÃO colidem na carga — regressão do bug corrigido em
    transform.add_stable_key (asset_key agora inclui a distribuidora).

    Validates: SYS-20 ("nunca duplicar OU sobrescrever indevidamente
    registros já carregados").
    """

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