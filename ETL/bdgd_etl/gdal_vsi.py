"""
bdgd_etl.gdal_vsi — GDAL /vsizip/ virtual filesystem interface.
Handles zero-disk-extraction access to ESRI Geodatabases (.gdb) directly inside ZIP files,
and automatic dynamic layer discovery without hardcoded layer names.
"""
from __future__ import annotations

import logging
import os
import zipfile
from pathlib import Path
from typing import Iterable

import pyogrio

logger = logging.getLogger(__name__)


def resolve_vsi_path(input_path: str | Path) -> tuple[str, str]:
    """Resolves the GDAL virtual filesystem path for a .zip or .gdb file.

    Returns
    -------
    tuple[str, str]
        (vsi_path, container_name)
        vsi_path: e.g. "/vsizip/D:/data/archive.zip/my_data.gdb" or "D:/data/my_data.gdb"
        container_name: name of the GDB folder
    """
    path_obj = Path(input_path).resolve()
    if not path_obj.exists():
        raise FileNotFoundError(f"Arquivo ou diretório de entrada não encontrado: {input_path}")

    # Case 1: Direct .gdb directory
    if path_obj.is_dir() and path_obj.suffix.lower() == ".gdb":
        norm_path = str(path_obj).replace("\\", "/")
        return norm_path, path_obj.name

    # Case 2: .zip archive
    if path_obj.suffix.lower() == ".zip":
        with zipfile.ZipFile(path_obj, "r") as z:
            namelist = z.namelist()

        # Find .gdb folder inside the zip
        gdb_dirs = set()
        for name in namelist:
            if ".gdb" in name.lower():
                # Extract the top-level path segment ending in .gdb
                parts = Path(name).parts
                for part in parts:
                    if part.lower().endswith(".gdb"):
                        # Reconstruct relative path inside zip
                        idx = parts.index(part)
                        gdb_subpath = "/".join(parts[: idx + 1])
                        gdb_dirs.add(gdb_subpath)
                        break

        if not gdb_dirs:
            raise ValueError(
                f"Nenhum diretório .gdb encontrado dentro do arquivo ZIP '{path_obj.name}'."
            )

        # Select the first GDB found
        chosen_gdb = sorted(list(gdb_dirs))[0]
        norm_zip = str(path_obj).replace("\\", "/")
        vsi_path = f"/vsizip/{norm_zip}/{chosen_gdb}"
        logger.info(
            "VSI GDAL resolvido: %s (GDB interno: %s)",
            vsi_path,
            chosen_gdb,
        )
        return vsi_path, chosen_gdb

    # If it's a directory containing a .gdb
    if path_obj.is_dir():
        gdbs = list(path_obj.glob("*.gdb"))
        if gdbs:
            norm_path = str(gdbs[0]).replace("\\", "/")
            return norm_path, gdbs[0].name

    raise ValueError(
        f"Formato não suportado para '{input_path}'. Esperado arquivo .zip ou diretório .gdb."
    )


def discover_all_layers(vsi_path: str) -> list[str]:
    """Automatically discovers all layer names in the geodatabase via GDAL.

    Does NOT hardcode any layer names. Uses PyOGRio (backed by GDAL C API).
    """
    logger.info("Descobrindo layers disponíveis via GDAL /vsizip/ em '%s' ...", vsi_path)
    try:
        raw_layers = pyogrio.list_layers(vsi_path)
        # raw_layers can be a 2D ndarray [[layer_name, geom_type], ...] or list
        layer_names: list[str] = []
        for item in raw_layers:
            if isinstance(item, (list, tuple)) or hasattr(item, "__getitem__"):
                layer_names.append(str(item[0]))
            else:
                layer_names.append(str(item))

        logger.info("Total de layers descobertas no GDB: %d", len(layer_names))
        return layer_names
    except Exception as exc:
        logger.error("Falha ao listar layers via PyOGRio: %s. Tentando Fiona...", exc)
        import fiona

        layers = fiona.listlayers(vsi_path)
        logger.info("Total de layers descobertas via Fiona: %d", len(layers))
        return list(layers)


def filter_layers(
    available_layers: Iterable[str],
    include_layers: list[str] | None = None,
    exclude_layers: list[str] | None = None,
    fallbacks: dict[str, dict[str, str]] | None = None,
) -> list[tuple[str, str | None]]:
    """Filters discovered layers based on configuration.

    If `include_layers` is empty, ALL available layers are processed!
    Also maps fallback layers (e.g. if user requests POSTE but only PONNOT exists).

    Returns
    -------
    list[tuple[str, str | None]]
        List of tuples: (actual_layer_name, alias_or_target_name)
    """
    available_list = list(available_layers)
    avail_lookup = {name.lower(): name for name in available_list}

    exclude_set = {x.lower() for x in (exclude_layers or [])}
    fallbacks = fallbacks or {}

    selected: list[tuple[str, str | None]] = []

    if include_layers:
        for requested in include_layers:
            req_lower = requested.lower()
            if req_lower in exclude_set:
                continue

            # Direct match
            if req_lower in avail_lookup:
                selected.append((avail_lookup[req_lower], requested))
                continue

            # Fallback match (e.g. POSTE -> PONNOT)
            fb = fallbacks.get(requested.upper()) or fallbacks.get(requested)
            if fb:
                source_layer = fb["layer"]
                if source_layer.lower() in avail_lookup:
                    actual = avail_lookup[source_layer.lower()]
                    logger.info(
                        "Layer solicitada '%s' resolvida via fallback para '%s'",
                        requested,
                        actual,
                    )
                    selected.append((actual, requested))
                    continue

            logger.warning(
                "Layer solicitada '%s' não encontrada no arquivo e sem fallback disponível.",
                requested,
            )
    else:
        # Include ALL available layers
        for layer in available_list:
            if layer.lower() not in exclude_set:
                selected.append((layer, None))

    return selected
