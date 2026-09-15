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
# Layers da BDGD
# ---------------------------------------------------------------------------
# Nomes confirmados pelo DDA ANEEL (Dicionário de Dados do SIG-R / PRODIST
# módulo 10). As feature classes dentro do .gdb são exatamente esses nomes,
# sem prefixos ou sufixos de distribuidora.
LAYERS: list[str] = [
    "POSTE",   # Suporte físico de rede (poste)
    "SUB",     # Subestação
    "UCBT",    # Unidade Consumidora de Baixa Tensão
    "UCMT",    # Unidade Consumidora de Média Tensão
    "SSDMT",   # Dispositivo de seccionamento/proteção de Média Tensão
]

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
    "POSTE": "COD_ID",
    "SUB":   "COD_ID",
    "UCBT":  "COD_ID",
    "UCMT":  "COD_ID",
    "SSDMT": "COD_ID",
}

# Fallback se KEY_COLUMN_BY_LAYER[layer] não existir no GeoDataFrame
KEY_COLUMN_FALLBACK: str = "FID"
