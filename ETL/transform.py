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

def _safe_repair_geometry(geom):
    """Tenta reparar uma geometria usando make_valid e buffer(0) como fallback."""
    if geom is None or getattr(geom, "is_empty", True):
        return geom

    # 1. Tenta make_valid
    try:
        repaired = make_valid(geom)
        if repaired is not None and not getattr(repaired, "is_empty", True) and repaired.is_valid:
            return repaired
    except Exception:  # pylint: disable=broad-except
        pass

    # 2. Fallback: buffer(0)
    try:
        repaired = geom.buffer(0)
        if repaired is not None and not getattr(repaired, "is_empty", True) and repaired.is_valid:
            return repaired
    except Exception:  # pylint: disable=broad-except
        pass

    return geom


def fix_geometry(gdf: gpd.GeoDataFrame) -> gpd.GeoDataFrame:
    """Remove/corrige geometrias inválidas, nulas ou vazias.

    Estratégia:
    1. Descarta feições com geometria None/NaN.
    2. Descarta feições com geometrias vazias (is_empty).
    3. Tenta reparar geometrias inválidas (self-intersections, laços) com:
       - shapely.make_valid()
       - buffer(0) como fallback se make_valid falhar ou mantiver a invalidade.
    4. Descarta feições que continuem inválidas ou vazias após a tentativa.

    Returns
    -------
    geopandas.GeoDataFrame
        GeoDataFrame sanitizado com apenas geometrias válidas e não-vazias.
    """
    n_before = len(gdf)
    if n_before == 0:
        return gdf

    # 1. Remove geometrias nulas (None/NaN)
    not_null_mask = ~gdf.geometry.isna()
    gdf = gdf[not_null_mask].copy()
    n_null_dropped = n_before - len(gdf)
    if n_null_dropped:
        logger.warning("Descartadas %d feições com geometria nula (None/NaN).", n_null_dropped)


    # 2. Remove geometrias vazias (is_empty, ex: POLYGON EMPTY)
    empty_mask = gdf.geometry.is_empty
    n_empty_dropped = empty_mask.sum()
    if n_empty_dropped:
        logger.warning("Descartadas %d feições com geometria vazia (is_empty).", n_empty_dropped)
        gdf = gdf[~empty_mask].copy()

    if len(gdf) == 0:
        logger.debug("fix_geometry: %d → 0 feições.", n_before)
        return gdf

    # 3. Tenta corrigir geometrias inválidas
    invalid_mask = ~gdf.geometry.is_valid
    n_invalid = invalid_mask.sum()
    if n_invalid:
        logger.info(
            "Detectadas %d geometrias inválidas (ex: self-intersections). Tentando correção (make_valid + buffer(0)) …",
            n_invalid,
        )
        gdf.loc[invalid_mask, "geometry"] = gdf.loc[invalid_mask, "geometry"].apply(_safe_repair_geometry)

        # 4. Avalia resultado pós-reparo: descarta as que ainda estiverem inválidas ou ficaram vazias
        still_invalid = ~gdf.geometry.is_valid
        now_empty = gdf.geometry.is_empty
        unfixable_mask = still_invalid | now_empty
        n_unfixable = unfixable_mask.sum()

        n_fixed = n_invalid - n_unfixable
        logger.info(
            "Correção de geometrias concluída: %d corrigidas com sucesso, %d irrecuperáveis descartadas.",
            n_fixed,
            n_unfixable,
        )

        if n_unfixable:
            gdf = gdf[~unfixable_mask].copy()

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
