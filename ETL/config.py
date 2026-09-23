from __future__ import annotations

import os
from dotenv import load_dotenv

load_dotenv()

DB_URL: str = os.getenv(
    "BDGD_DB_URL",
    "postgresql://postgres:postgres@localhost:5432/bdgd",
)

UPLOADS_DIR: str = os.getenv("BDGD_UPLOADS_DIR", "../uploads")

SCHEMA: str = "bdgd"

TARGET_CRS: str = "EPSG:4326"

SOURCE_CRS_FALLBACK: str = "EPSG:4674"

CONSUMER_LAYERS: list[str] = [
    "UCBT",
    "UCMT",
]

INFRASTRUCTURE_LAYERS: list[str] = [
    "POSTE",
    "SUB",
]

NETWORK_SEGMENT_LAYERS: list[str] = [
    "SSDBT",
    "SSDMT",
    "SSDAT",
]

RELEVANT_LAYERS: list[str] = [
    *CONSUMER_LAYERS,
    *INFRASTRUCTURE_LAYERS,
    *NETWORK_SEGMENT_LAYERS,
]

LAYERS: list[str] = RELEVANT_LAYERS

KEY_COLUMN_BY_LAYER: dict[str, str] = {
    "UCBT":  "COD_ID",
    "UCMT":  "COD_ID",
    "POSTE": "COD_ID",
    "SUB":   "COD_ID",
    "SSDBT": "COD_ID",
    "SSDMT": "COD_ID",
    "SSDAT": "COD_ID",
}

KEY_COLUMN_FALLBACK: str = "FID"

# Modelo BDGD V1.0/V1.1 (Manual de Instrucoes BDGD/ANEEL) descontinuou a
# entidade POSTE: postes agora sao um subtipo de PONNOT (TIP_PN = "POS").
LAYER_FALLBACKS: dict[str, dict[str, str]] = {
    "POSTE": {
        "layer": "PONNOT",
        "filter_col": "TIP_PN",
        "filter_value": "POS",
    },
}