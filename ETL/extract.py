"""
extract.py — Leitura de layers do arquivo .gdb da BDGD.

Funções públicas
----------------
list_available_layers(gdb_path)  → list[str]
select_relevant_layers(available_layers, requested_layers=None) → list[str]
read_layer(gdb_path, layer_name) → geopandas.GeoDataFrame

Notas de implementação
----------------------
- Usa fiona.listlayers() para inspecionar o arquivo antes de abrir qualquer
  layer. Isso permite detectar nomes de layer diferentes do esperado sem
  falhar com KeyError.
- read_layer() não altera nada — devolve o GeoDataFrame cru, exatamente
  como saiu do arquivo. Toda transformação fica em transform.py.
- O driver OpenFileGDB (GDAL open-source) é suficiente para leitura; nenhuma
  licença ESRI é necessária.
"""
from __future__ import annotations

import logging
from collections.abc import Iterable
from pathlib import Path

import fiona
import geopandas as gpd

from config import LAYERS

logger = logging.getLogger(__name__)


def _layer_lookup(layer_names: Iterable[str]) -> dict[str, str]:
    """Cria lookup case-insensitive preservando o primeiro nome original."""
    lookup: dict[str, str] = {}
    for name in layer_names:
        lookup.setdefault(name.lower(), name)
    return lookup


def _resolve_available_layer(layer_name: str, available_layers: Iterable[str]) -> str | None:
    """Retorna o nome real da layer no GDB para um nome canônico/configurado."""
    if layer_name in available_layers:
        return layer_name
    return _layer_lookup(available_layers).get(layer_name.lower())


def list_available_layers(gdb_path: str | Path) -> list[str]:
    """Retorna todas as layers presentes no .gdb e loga diferenças vs. config.

    Parameters
    ----------
    gdb_path:
        Caminho para a pasta com extensão .gdb.

    Returns
    -------
    list[str]
        Lista de nomes de layers encontrados no arquivo.
    """
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

    # --- comparação com as layers esperadas em config.py -----------------
    expected_lookup = _layer_lookup(LAYERS)
    found_lookup = _layer_lookup(found)

    ausentes = [
        layer
        for layer in LAYERS
        if layer.lower() not in found_lookup
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

    Parameters
    ----------
    available_layers:
        Layers existentes no .gdb.
    requested_layers:
        Subconjunto opcional vindo da CLI. Mesmo quando informado, layers fora
        de config.LAYERS são ignoradas para garantir o descarte do restante.

    Returns
    -------
    list[str]
        Nomes canônicos das layers relevantes encontradas, na ordem de config.LAYERS.
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
        actual_layer = _resolve_available_layer(layer, available_layers)
        if actual_layer is None:
            missing_layers.append(layer)
            continue

        if actual_layer != layer:
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
    """Lê uma layer do .gdb e devolve um GeoDataFrame cru.

    Parameters
    ----------
    gdb_path:
        Caminho para a pasta com extensão .gdb.
    layer_name:
        Nome canônico/configurado da layer a ser lida.

    Returns
    -------
    geopandas.GeoDataFrame
        Dados brutos da layer, sem nenhuma transformação.

    Raises
    ------
    ValueError
        Se a layer não existir no arquivo.
    RuntimeError
        Se ocorrer qualquer outro erro de leitura.
    """
    gdb_path = str(gdb_path)
    available = fiona.listlayers(gdb_path)
    actual_layer_name = _resolve_available_layer(layer_name, available)

    if actual_layer_name is None:
        # Tenta correspondência case-insensitive para ajudar no diagnóstico
        ci_match = [n for n in available if n.lower() == layer_name.lower()]
        hint = f" (nome similar encontrado: {ci_match})" if ci_match else ""
        raise ValueError(
            f"Layer '{layer_name}' não encontrada no arquivo{hint}. "
            f"Layers disponíveis: {available}"
        )

    try:
        gdf = gpd.read_file(gdb_path, layer=actual_layer_name)
    except Exception as exc:
        raise RuntimeError(
            f"Erro ao ler layer '{actual_layer_name}' de '{gdb_path}': {exc}"
        ) from exc

    logger.info(
        "Layer '%s' lida: %d feições, colunas=%s, CRS=%s",
        layer_name,
        len(gdf),
        list(gdf.columns),
        gdf.crs,
    )
    return gdf
