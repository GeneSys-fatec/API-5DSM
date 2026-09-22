# ETL/Dockerfile
#
# Imagem para o serviço `etl` do docker-compose.dev.yml (raiz do repositório).
# Usa uma imagem base com GDAL nativo pré-compilado (necessário para o driver
# OpenFileGDB usado por `fiona`/`geopandas` ao ler arquivos .gdb da BDGD) em vez
# de `python:3.11-slim`, que não traz GDAL.
#
# Uso local (fora deste Dockerfile):
#   docker compose --profile etl run --rm etl python main.py <gdb> <dist> <regiao>
FROM ghcr.io/osgeo/gdal:ubuntu-small-3.8.4

# A imagem base (Ubuntu 22.04 "jammy") traz Python 3.10 nos repositórios
# padrão. O README do módulo exige Python >= 3.10, mas o design pede
# especificamente Python 3.11 — instalado aqui via deadsnakes.
#
# IMPORTANTE: nunca instalar `gdal-bin`/`libgdal-dev`/pacotes equivalentes via
# apt nesta imagem — a documentação oficial do osgeo/gdal alerta que isso
# conflita com o build customizado do GDAL já presente na imagem e pode
# quebrar o container. Instalamos apenas Python 3.11 e ferramentas de build
# genéricas (necessárias para compilar a extensão C do `fiona` contra o GDAL
# já existente).
RUN apt-get update \
    && apt-get install -y --no-install-recommends software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        python3.11 \
        python3.11-dev \
        python3.11-venv \
        python3.11-distutils \
        python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Garante que `python3`/`pip3` no PATH apontem para o Python 3.11 recém
# instalado. O GDAL nativo é uma biblioteca compartilhada (libgdal.so) e não
# depende da versão do interpretador Python usada para compilar o `fiona`.
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 \
    && python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel

# A imagem `ubuntu-small` do GDAL não inclui o utilitário `gdal-config`
# (apenas as bibliotecas/headers de runtime, instalados em /usr/include e
# /usr/lib pelo build da própria imagem base), então apontamos o `fiona`
# diretamente para a versão e os caminhos de header/lib do GDAL já
# instalado, evitando qualquer instalação paralela via apt.
ENV GDAL_VERSION=3.8.4 \
    CPLUS_INCLUDE_PATH=/usr/include \
    C_INCLUDE_PATH=/usr/include \
    LD_LIBRARY_PATH=/usr/lib

WORKDIR /app

# Copia primeiro só o requirements.txt para aproveitar o cache de camadas do
# Docker quando o código do módulo mudar sem alterar as dependências.
COPY requirements.txt ./
RUN python3 -m pip install --no-cache-dir -r requirements.txt

# Copia o código do módulo ETL (config.py, extract.py, transform.py,
# schema.py, load.py, main.py). `tests/`, `.env`, `__pycache__` e
# `.pytest_cache` são excluídos via .dockerignore.
COPY . .

# Mantém o container vivo por padrão. O pipeline é uma ferramenta de linha de
# comando invocada pontualmente, não um serviço de longa duração:
#   docker compose --profile etl run --rm etl python main.py <gdb> <dist> <regiao>
CMD ["tail", "-f", "/dev/null"]
