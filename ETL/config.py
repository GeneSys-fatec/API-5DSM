"""
config.py — Configurações centralizadas do ETL BDGD.

Variáveis de ambiente reconhecidas:
    BDGD_DB_URL  – connection string SQLAlchemy completa
                   (default: postgresql://postgres:postgres@localhost:5432/bdgd)
"""
from __future__ import annotations

import os
from dotenv import load_dotenv

load_dotenv()

# ---------------------------------------------------------------------------
# Banco de dados
# ---------------------------------------------------------------------------
DB_URL: str = os.getenv(
    "BDGD_DB_URL",
    "postgresql://postgres:postgres@localhost:5432/bdgd",
)

SCHEMA: str = "bdgd"

# ---------------------------------------------------------------------------
# Sistemas de referência
# ---------------------------------------------------------------------------
# CRS alvo — WGS 84 geográfico
TARGET_CRS: str = "EPSG:4326"

# CRS que a BDGD DEVE ter por norma ANEEL/PRODIST (SIRGAS 2000 geográfico).
# Usado como fallback quando o GeoDataFrame não carrega CRS do arquivo.
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

# ---------------------------------------------------------------------------
# Campo chave por layer
# ---------------------------------------------------------------------------
# COD_ID é o identificador único exigido pela norma ANEEL para todas as
# entidades geográficas. O pipeline usa esse campo para:
#   1. Deduplicação dentro do GeoDataFrame
#   2. Geração da chave estável (asset_key)
#   3. Condição ON CONFLICT no upsert
#
# Se numa distribuidora específica o campo não existir, o pipeline loga um
# aviso e tenta o fallback "FID" (objeto interno do GDB). Se nenhum dos dois
# existir, a layer inteira é marcada como ERRO e as demais continuam.
KEY_COLUMN_BY_LAYER: dict[str, str] = {
    "UCBT":  "COD_ID",
    "UCMT":  "COD_ID",
    "POSTE": "COD_ID",
    "SUB":   "COD_ID",
    "SSDBT": "COD_ID",
    "SSDMT": "COD_ID",
    "SSDAT": "COD_ID",
}

# Fallback se KEY_COLUMN_BY_LAYER[layer] não existir no GeoDataFrame
KEY_COLUMN_FALLBACK: str = "FID"
