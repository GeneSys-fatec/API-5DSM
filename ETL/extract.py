"""
extract.py — Leitura de layers do arquivo .gdb da BDGD.

Funções públicas
----------------
list_available_layers(gdb_path)  → list[str]
select_relevant_layers(available_layers, requested_layers=None) → list[str]
read_layer(gdb_path, layer_name) → geopandas.GeoDataFrame
"""
from __future__ import annotations

import logging
from collections.abc import Iterable
from pathlib import Path

import fiona
import geopandas as gpd

from config import LAYER_FALLBACKS, LAYERS

logger = logging.getLogger(__name__)


def _layer_lookup(layer_names: Iterable[str]) -> dict[str, str]:
    lookup: dict[str, str] = {}
    for name in layer_names:
        lookup.setdefault(name.lower(), name)
    return lookup


def _resolve_available_layer(layer_name: str, available_layers: Iterable[str]) -> str | None:
    if layer_name in available_layers:
        return layer_name
    return _layer_lookup(available_layers).get(layer_name.lower())


def _resolve_layer_source(
    layer_name: str, available_layers: Iterable[str]
) -> tuple[str, dict[str, str] | None] | None:
    """Resolve o nome real da layer, incluindo fallback (config.LAYER_FALLBACKS)."""
    direct_match = _resolve_available_layer(layer_name, available_layers)
    if direct_match is not None:
        return direct_match, None

    fallback = LAYER_FALLBACKS.get(layer_name)
    if fallback is None:
        return None

    fallback_layer_match = _resolve_available_layer(fallback["layer"], available_layers)
    if fallback_layer_match is None:
        return None

    return fallback_layer_match, fallback


def list_available_layers(gdb_path: str | Path) -> list[str]:
    gdb_path = str(gdb_path)
    try:
        found = fiona.listlayers(gdb_path)
    except Exception as exc:
        raise RuntimeError(
            f"Não foi possível listar layers em '{gdb_path}': {exc}"
        ) from exc

    logger.info("Layers encontradas no GDB (%d):", len(found))
    for name in found:
        logger.info("  • %s", name)

    expected_lookup = _layer_lookup(LAYERS)
    found_lookup = _layer_lookup(found)

    ausentes = [
        layer
        for layer in LAYERS
        if layer.lower() not in found_lookup
        and _resolve_layer_source(layer, found) is None
    ]
    extras = [
        layer
        for layer in found
        if layer.lower() not in expected_lookup
    ]

    if ausentes:
        logger.warning(
            "Layers esperadas (config.LAYERS) NÃO encontradas no GDB: %s",
            sorted(ausentes),
        )
    if extras:
        logger.info(
            "Layers extras no GDB (não configuradas para importação): %s",
            sorted(extras),
        )

    return list(found)


def select_relevant_layers(
    available_layers: Iterable[str],
    requested_layers: Iterable[str] | None = None,
) -> list[str]:
    """Seleciona apenas as layers relevantes configuradas para o desafio.

    Inclui layers resolvidas via config.LAYER_FALLBACKS (ex. "POSTE" quando
    o .gdb só tem "PONNOT") — read_layer() aplica o filtro correspondente.
    """
    available_layers = list(available_layers)
    configured_lookup = _layer_lookup(LAYERS)

    if requested_layers:
        requested_set: set[str] = set()
        ignored_requested: list[str] = []

        for layer in requested_layers:
            canonical_layer = configured_lookup.get(layer.lower())
            if canonical_layer is None:
                ignored_requested.append(layer)
                continue
            requested_set.add(canonical_layer)

        if ignored_requested:
            logger.warning(
                "Layers solicitadas fora do conjunto relevante serão descartadas: %s",
                sorted(ignored_requested),
            )

        candidate_layers = [layer for layer in LAYERS if layer in requested_set]
    else:
        candidate_layers = list(LAYERS)

    selected_layers: list[str] = []
    missing_layers: list[str] = []

    for layer in candidate_layers:
        resolved = _resolve_layer_source(layer, available_layers)
        if resolved is None:
            missing_layers.append(layer)
            continue

        actual_layer, fallback_spec = resolved
        if fallback_spec is not None:
            logger.warning(
                "Layer '%s' não encontrada no GDB; usando fallback '%s' "
                "filtrado por %s=%s.",
                layer,
                actual_layer,
                fallback_spec["filter_col"],
                fallback_spec["filter_value"],
            )
        elif actual_layer != layer:
            logger.warning(
                "Layer '%s' encontrada no GDB como '%s'; usando nome canônico '%s'.",
                layer,
                actual_layer,
                layer,
            )
        selected_layers.append(layer)

    selected_layer_names = {selected.lower() for selected in selected_layers}
    discarded_layers = [
        layer
        for layer in available_layers
        if layer.lower() not in selected_layer_names
    ]

    if missing_layers:
        logger.warning(
            "Layers relevantes não encontradas no GDB e ignoradas: %s",
            sorted(missing_layers),
        )
    if discarded_layers:
        logger.info(
            "Layers descartadas por não serem relevantes ao desafio: %s",
            sorted(discarded_layers),
        )

    return selected_layers


def read_layer(gdb_path: str | Path, layer_name: str) -> gpd.GeoDataFrame:
    """Lê uma layer do .gdb. Se `layer_name` não existir mas tiver fallback
    configurado (ex. "POSTE" → "PONNOT"), lê o fallback já filtrado.

    Raises
    ------
    ValueError
        Se a layer não existir no arquivo (nem diretamente, nem via fallback).
    RuntimeError
        Se ocorrer qualquer outro erro de leitura.
    """
    gdb_path = str(gdb_path)
    available = fiona.listlayers(gdb_path)
    resolved = _resolve_layer_source(layer_name, available)

    if resolved is None:
        ci_match = [n for n in available if n.lower() == layer_name.lower()]
        hint = f" (nome similar encontrado: {ci_match})" if ci_match else ""
        raise ValueError(
            f"Layer '{layer_name}' não encontrada no arquivo{hint}. "
            f"Layers disponíveis: {available}"
        )

    actual_layer_name, fallback_spec = resolved

    try:
        gdf = gpd.read_file(gdb_path, layer=actual_layer_name)
    except Exception as exc:
        raise RuntimeError(
            f"Erro ao ler layer '{actual_layer_name}' de '{gdb_path}': {exc}"
        ) from exc

    if fallback_spec is not None:
        filter_col = fallback_spec["filter_col"]
        filter_value = fallback_spec["filter_value"]
        if filter_col not in gdf.columns:
            raise RuntimeError(
                f"Fallback de '{layer_name}' para '{actual_layer_name}' falhou: "
                f"coluna de filtro '{filter_col}' não existe. "
                f"Colunas disponíveis: {list(gdf.columns)}"
            )
        n_before = len(gdf)
        gdf = gdf[gdf[filter_col] == filter_value].copy()
        logger.info(
            "Layer '%s' resolvida via fallback '%s' (%s=%s): %d de %d feições "
            "mantidas após o filtro.",
            layer_name, actual_layer_name, filter_col, filter_value, len(gdf), n_before,
        )

    logger.info(
        "Layer '%s' lida: %d feições, colunas=%s, CRS=%s",
        layer_name,
        len(gdf),
        list(gdf.columns),
        gdf.crs,
    )
    return gdf