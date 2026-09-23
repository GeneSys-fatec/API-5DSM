# Uso:
#   docker compose --profile etl run --rm etl python main.py <gdb> <dist> <regiao>
FROM ghcr.io/osgeo/gdal:ubuntu-small-3.8.4

# NUNCA instalar gdal-bin/libgdal-dev via apt nesta imagem — conflita com o
# build customizado do GDAL ja presente e quebra o container.
ENV DEBIAN_FRONTEND=noninteractive TZ=UTC

RUN apt-get update \
    && apt-get install -y --no-install-recommends software-properties-common gnupg dirmngr \
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

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 \
    && python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel

ENV GDAL_VERSION=3.8.4 \
    CPLUS_INCLUDE_PATH=/usr/include \
    C_INCLUDE_PATH=/usr/include \
    LD_LIBRARY_PATH=/usr/lib

WORKDIR /app

COPY requirements.txt ./
RUN python3 -m pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["tail", "-f", "/dev/null"]