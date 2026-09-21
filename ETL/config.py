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

# ---------------------------------------------------------------------------
# Layers relevantes da BDGD
# ---------------------------------------------------------------------------
# O desafio usa apenas consumidores, postes, subestações e segmentos de rede.
# As demais feature classes do .gdb baixado da zona raw devem ser descartadas.
CONSUMER_LAYERS: list[str] = [
    "UCBT",  # Unidade Consumidora de Baixa Tensão
    "UCMT",  # Unidade Consumidora de Média Tensão
]

INFRASTRUCTURE_LAYERS: list[str] = [
    "POSTE",  # Suporte físico de rede (poste)
    "SUB",    # Subestação
]

NETWORK_SEGMENT_LAYERS: list[str] = [
    "SSDBT",  # Segmento de Rede de Baixa Tensão
    "SSDMT",  # Segmento de Rede de Média Tensão
    "SSDAT",  # Segmento de Rede de Alta Tensão
]

RELEVANT_LAYERS: list[str] = [
    *CONSUMER_LAYERS,
    *INFRASTRUCTURE_LAYERS,
    *NETWORK_SEGMENT_LAYERS,
]

# Mantém compatibilidade com o restante do ETL.
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
