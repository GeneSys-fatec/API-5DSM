"""
transform.py — Transformações geoespaciais sobre os GeoDataFrames da BDGD.

Funções públicas
----------------
reproject(gdf, target_crs, source_crs_fallback) → GeoDataFrame
fix_geometry(gdf)                                → GeoDataFrame
deduplicate(gdf, key_col)                        → GeoDataFrame
add_stable_key(gdf, layer_name, key_col)         → GeoDataFrame
prepare_layer(gdf, layer_name, key_col)          → GeoDataFrame   [pipeline completo]

Notas de implementação
----------------------
reproject
    - Se gdf.crs for None (o GDB não reportou o CRS), define
      source_crs_fallback com WARNING — não silencia nem ignora.
      A norma ANEEL exige SIRGAS 2000 (EPSG:4674), portanto assumir isso
      é correto na esmagadora maioria dos casos; qualquer exceção deve ser
      tratada com um ajuste manual no source_crs_fallback em config.py.

fix_geometry
    - Descarta feições com geometria None.
    - Tenta corrigir geometrias inválidas com buffer(0); se ainda inválida,
      descarta a feição e loga um aviso.

deduplicate
    - Remove duplicatas pelo campo chave, mantendo a primeira ocorrência.
    - Se o campo chave não existir no GDF, levanta KeyError (propagado
      para main.py, que captura por layer).

add_stable_key
    - Cria a coluna `asset_key` no formato "<LAYER>::<COD_ID>".
    - Essa chave é o identificador usado na cláusula ON CONFLICT do upsert.
"""
from __future__ import annotations

import logging

import geopandas as gpd
from shapely.validation import make_valid

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Reprojeção
# ---------------------------------------------------------------------------

def reproject(
    gdf: gpd.GeoDataFrame,
    target_crs: str,
    source_crs_fallback: str,
) -> gpd.GeoDataFrame:
    """Reprojeta o GeoDataFrame para *target_crs*.

    Se o CRS de origem não estiver definido, usa *source_crs_fallback* com
    WARNING (nunca silencia o problema).

    Parameters
    ----------
    gdf:
        GeoDataFrame cru vindo de extract.read_layer().
    target_crs:
        CRS destino, ex. "EPSG:4326".
    source_crs_fallback:
        CRS a assumir quando gdf.crs for None, ex. "EPSG:4674".

    Returns
    -------
    geopandas.GeoDataFrame
        GeoDataFrame reprojetado para target_crs.

    Raises
    ------
    ValueError
        Nunca levantado por CRS None (isso é tratado internamente).
        Pode vir do pyproj se os códigos de CRS forem inválidos.
    """
    if gdf.crs is None:
        logger.warning(
            "CRS não definido no GeoDataFrame. "
            "Assumindo '%s' (SIRGAS 2000, padrão ANEEL). "
            "Se o CRS real for diferente, ajuste SOURCE_CRS_FALLBACK em config.py.",
            source_crs_fallback,
        )
        gdf = gdf.set_crs(source_crs_fallback)
    else:
        logger.debug("CRS de origem detectado: %s", gdf.crs)

    if gdf.crs.to_epsg() == int(target_crs.split(":")[1]):
        logger.debug("CRS já é %s — nenhuma reprojeção necessária.", target_crs)
        return gdf

    logger.info("Reprojetando %s → %s", gdf.crs, target_crs)
    return gdf.to_crs(target_crs)


# ---------------------------------------------------------------------------
# Correção de geometria
# ---------------------------------------------------------------------------

def fix_geometry(gdf: gpd.GeoDataFrame) -> gpd.GeoDataFrame:
    """Remove/corrige geometrias inválidas ou nulas.

    Estratégia:
    1. Descarta feições com geometria None.
    2. Tenta reparar geometrias inválidas com shapely.make_valid().
    3. Descarta feições que ainda estejam inválidas após a tentativa.

    Returns
    -------
    geopandas.GeoDataFrame
        GeoDataFrame com apenas geometrias válidas.
    """
    n_before = len(gdf)

    # 1. Remove geometrias nulas
    gdf = gdf[gdf.geometry.notna()].copy()
    n_null_dropped = n_before - len(gdf)
    if n_null_dropped:
        logger.warning("Descartadas %d feições com geometria None.", n_null_dropped)

    # 2. Tenta corrigir geometrias inválidas
    invalid_mask = ~gdf.geometry.is_valid
    n_invalid = invalid_mask.sum()
    if n_invalid:
        logger.info("Tentando corrigir %d geometrias inválidas com make_valid().", n_invalid)
        gdf.loc[invalid_mask, "geometry"] = gdf.loc[invalid_mask, "geometry"].apply(
            make_valid
        )

        # 3. Descarta as que ainda estejam inválidas
        still_invalid = ~gdf.geometry.is_valid
        n_still = still_invalid.sum()
        if n_still:
            logger.warning(
                "Descartadas %d feições que não puderam ser corrigidas.", n_still
            )
            gdf = gdf[~still_invalid].copy()

    logger.debug("fix_geometry: %d → %d feições.", n_before, len(gdf))
    return gdf


# ---------------------------------------------------------------------------
# Deduplicação
# ---------------------------------------------------------------------------

def deduplicate(gdf: gpd.GeoDataFrame, key_col: str) -> gpd.GeoDataFrame:
    """Remove linhas duplicadas pelo campo *key_col*.

    Parameters
    ----------
    key_col:
        Nome da coluna identificadora (ex. "COD_ID").

    Returns
    -------
    geopandas.GeoDataFrame

    Raises
    ------
    KeyError
        Se *key_col* não existir no GeoDataFrame.
    """
    if key_col not in gdf.columns:
        raise KeyError(
            f"Campo chave '{key_col}' não encontrado. "
            f"Colunas disponíveis: {list(gdf.columns)}"
        )

    n_before = len(gdf)
    gdf = gdf.drop_duplicates(subset=[key_col], keep="first").copy()
    n_dupes = n_before - len(gdf)
    if n_dupes:
        logger.warning("Removidas %d feições duplicadas (campo '%s').", n_dupes, key_col)
    return gdf


# ---------------------------------------------------------------------------
# Chave estável
# ---------------------------------------------------------------------------

def add_stable_key(
    gdf: gpd.GeoDataFrame,
    layer_name: str,
    key_col: str,
) -> gpd.GeoDataFrame:
    """Adiciona a coluna `asset_key` com formato "<LAYER>::<COD_ID>".

    Essa chave é usada na cláusula ON CONFLICT do upsert no PostGIS.

    Parameters
    ----------
    layer_name:
        Nome da layer (ex. "POSTE").
    key_col:
        Nome da coluna identificadora no GeoDataFrame (ex. "COD_ID").

    Returns
    -------
    geopandas.GeoDataFrame
    """
    if key_col not in gdf.columns:
        raise KeyError(
            f"Campo chave '{key_col}' não encontrado ao gerar asset_key. "
            f"Colunas disponíveis: {list(gdf.columns)}"
        )

    gdf = gdf.copy()
    gdf["asset_key"] = layer_name + "::" + gdf[key_col].astype(str)
    logger.debug("asset_key gerado. Exemplo: %s", gdf["asset_key"].iloc[0] if len(gdf) else "(vazio)")
    return gdf


# ---------------------------------------------------------------------------
# Pipeline completo de transformação
# ---------------------------------------------------------------------------

def prepare_layer(
    gdf: gpd.GeoDataFrame,
    layer_name: str,
    key_col: str,
    target_crs: str,
    source_crs_fallback: str,
) -> gpd.GeoDataFrame:
    """Executa o pipeline completo de transformação para uma layer.

    Ordem: reproject → fix_geometry → deduplicate → add_stable_key.

    Parameters
    ----------
    gdf:
        GeoDataFrame cru de extract.read_layer().
    layer_name:
        Nome da layer (ex. "POSTE").
    key_col:
        Campo identificador para deduplicação e chave estável.
    target_crs:
        CRS de destino (ex. "EPSG:4326").
    source_crs_fallback:
        CRS a assumir se gdf.crs for None (ex. "EPSG:4674").

    Returns
    -------
    geopandas.GeoDataFrame
        GeoDataFrame pronto para carga no PostGIS.
    """
    gdf = reproject(gdf, target_crs, source_crs_fallback)
    gdf = fix_geometry(gdf)
    gdf = deduplicate(gdf, key_col)
    gdf = add_stable_key(gdf, layer_name, key_col)
    return gdf
