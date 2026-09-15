"""
extract.py — Leitura de layers do arquivo .gdb da BDGD.

Funções públicas
----------------
list_available_layers(gdb_path)  → list[str]
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
from pathlib import Path

import fiona
import geopandas as gpd

from config import LAYERS

logger = logging.getLogger(__name__)


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
    """Lê uma layer do .gdb e devolve um GeoDataFrame cru.

    Parameters
    ----------
    gdb_path:
        Caminho para a pasta com extensão .gdb.
    layer_name:
        Nome exato da layer a ser lida (case-sensitive).

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

    if layer_name not in available:
        # Tenta correspondência case-insensitive para ajudar no diagnóstico
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
