from __future__ import annotations

import os
from dotenv import load_dotenv

load_dotenv()

DB_URL: str = os.getenv(
    "BDGD_DB_URL",
    "postgresql://postgres:postgres@localhost:5432/bdgd",
)

SCHEMA: str = "bdgd"

TARGET_CRS: str = "EPSG:4326"

SOURCE_CRS_FALLBACK: str = "EPSG:4674"

LAYERS: list[str] = [
    "POSTE",
    "SUB",
    "UCBT",
    "UCMT",
    "SSDMT",
]

KEY_COLUMN_BY_LAYER: dict[str, str] = {
    "POSTE": "COD_ID",
    "SUB":   "COD_ID",
    "UCBT":  "COD_ID",
    "UCMT":  "COD_ID",
    "SSDMT": "COD_ID",
}

KEY_COLUMN_FALLBACK: str = "FID"
