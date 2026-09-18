from __future__ import annotations

import logging

import geopandas as gpd
from shapely.validation import make_valid

logger = logging.getLogger(__name__)


def reproject(
    gdf: gpd.GeoDataFrame,
    target_crs: str,
    source_crs_fallback: str,
) -> gpd.GeoDataFrame:
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


def fix_geometry(gdf: gpd.GeoDataFrame) -> gpd.GeoDataFrame:
    n_before = len(gdf)

    gdf = gdf[gdf.geometry.notna()].copy()
    n_null_dropped = n_before - len(gdf)
    if n_null_dropped:
        logger.warning("Descartadas %d feições com geometria None.", n_null_dropped)

    invalid_mask = ~gdf.geometry.is_valid
    n_invalid = invalid_mask.sum()
    if n_invalid:
        logger.info("Tentando corrigir %d geometrias inválidas com make_valid().", n_invalid)
        gdf.loc[invalid_mask, "geometry"] = gdf.loc[invalid_mask, "geometry"].apply(
            make_valid
        )

        still_invalid = ~gdf.geometry.is_valid
        n_still = still_invalid.sum()
        if n_still:
            logger.warning(
                "Descartadas %d feições que não puderam ser corrigidas.", n_still
            )
            gdf = gdf[~still_invalid].copy()

    logger.debug("fix_geometry: %d → %d feições.", n_before, len(gdf))
    return gdf


def deduplicate(gdf: gpd.GeoDataFrame, key_col: str) -> gpd.GeoDataFrame:
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


def add_stable_key(
    gdf: gpd.GeoDataFrame,
    layer_name: str,
    dist_name: str,
    key_col: str,
) -> gpd.GeoDataFrame:
    if key_col not in gdf.columns:
        raise KeyError(
            f"Campo chave '{key_col}' não encontrado ao gerar asset_key. "
            f"Colunas disponíveis: {list(gdf.columns)}"
        )

    gdf = gdf.copy()
    gdf["asset_key"] = layer_name + "::" + dist_name + "::" + gdf[key_col].astype(str)
    logger.debug("asset_key gerado. Exemplo: %s", gdf["asset_key"].iloc[0] if len(gdf) else "(vazio)")
    return gdf


def prepare_layer(
    gdf: gpd.GeoDataFrame,
    layer_name: str,
    dist_name: str,
    key_col: str,
    target_crs: str,
    source_crs_fallback: str,
) -> gpd.GeoDataFrame:
    gdf = reproject(gdf, target_crs, source_crs_fallback)
    gdf = fix_geometry(gdf)
    gdf = deduplicate(gdf, key_col)
    gdf = add_stable_key(gdf, layer_name, dist_name, key_col)
    return gdf
