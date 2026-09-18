from __future__ import annotations

import logging
from pathlib import Path

import fiona
import geopandas as gpd

from config import LAYERS

logger = logging.getLogger(__name__)


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

    expected_set = set(LAYERS)
    found_set = set(found)

    ausentes = expected_set - found_set
    extras = found_set - expected_set

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


def read_layer(gdb_path: str | Path, layer_name: str) -> gpd.GeoDataFrame:
    gdb_path = str(gdb_path)
    available = fiona.listlayers(gdb_path)

    if layer_name not in available:
        ci_match = [n for n in available if n.lower() == layer_name.lower()]
        hint = f" (nome similar encontrado: {ci_match})" if ci_match else ""
        raise ValueError(
            f"Layer '{layer_name}' não encontrada no arquivo{hint}. "
            f"Layers disponíveis: {available}"
        )

    try:
        gdf = gpd.read_file(gdb_path, layer=layer_name)
    except Exception as exc:
        raise RuntimeError(
            f"Erro ao ler layer '{layer_name}' de '{gdb_path}': {exc}"
        ) from exc

    logger.info(
        "Layer '%s' lida: %d feições, colunas=%s, CRS=%s",
        layer_name,
        len(gdf),
        list(gdf.columns),
        gdf.crs,
    )
    return gdf
