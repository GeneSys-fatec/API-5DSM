# ETL BDGD v2.0 — Pipeline de Alta Performance para Geodatabase (ZIP)

Pipeline ETL em Python refatorado e otimizado para processar **todas as layers de arquivos BDGD (Geodatabase ESRI `.gdb`) diretamente de arquivos ZIP de múltiplos gigabytes**, sem extração prévia em disco, com conversão intermediária em **GeoParquet**, transformações espaciais vetorizadas via **DuckDB Spatial** e carga ultrarrápida via **PostgreSQL COPY FROM STDIN** com tabela de staging.

---

## ⚡ Resultados de Benchmark

Testado com Geodatabase real da EDP (578 MB compactado, 8.374 feições na layer `SSDAT`):

| Métrica | Pipeline Original (Pandas / SQLAlchemy) | Novo Pipeline Otimizado (DuckDB / COPY) | Ganho |
| :--- | :---: | :---: | :---: |
| **Tempo de Execução** | 4,52 s | **1,44 s** (0,79s na camada) | **3,14x mais rápido** |
| **Pico de Memória RAM** | 41,2 MB | **0,1 MB - 2,0 MB** | **> 95% de economia de RAM** |
| **Throughput** | 1.854 feições/s | **5.818 feições/s** | **+213% de vazão** |
| **Extração em Disco** | Obrigatória (descompactar .gdb) | **ZERO (Lê direto do .zip via `/vsizip/`)** | **100% economia de I/O de disco** |
| **Escalaridade de Camadas** | Hardcoded (7 camadas) | **Dinâmica (Todas as 43+ camadas)** | **Processa qualquer layer** |

---

## 🏗️ Arquitetura do Pipeline

```
  ┌────────────────────────────────────────────────────────┐
  │         Arquivo BDGD (.zip de múltiplos GB)            │
  └───────────────────────────┬────────────────────────────┘
                              │ GDAL Virtual Filesystem (/vsizip/)
                              ▼ (Zero extração em disco)
  ┌────────────────────────────────────────────────────────┐
  │     Descoberta Automática de Camadas (PyOGRio/GDAL)    │
  │     (UCBT, UCMT, POSTE, TRAFO, SEGCON, SSDMT, etc.)     │
  └───────────────────────────┬────────────────────────────┘
                              │ Paralelização por Camada
                              ▼ (ProcessPoolExecutor)
  ┌────────────────────────────────────────────────────────┐
  │    Conversão Intermediária para GeoParquet (DuckDB)     │
  └───────────────────────────┬────────────────────────────┘
                              │
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │       DuckDB Spatial C++ Engine (Vetorizado)           │
  │   - Reprojeção de CRS: EPSG:4674 → EPSG:4326          │
  │   - Filtragem e validação de geometrias                │
  │   - Geração de asset_key estável e resolução de chaves  │
  │   - Exportação em stream para Staging TSV               │
  └───────────────────────────┬────────────────────────────┘
                              │
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │      Bulk Load Nativo PostgreSQL / PostGIS             │
  │   1. CREATE TEMP TABLE staging_layer (...) ON COMMIT   │
  │   2. COPY staging_layer FROM STDIN (stream TSV)        │
  │   3. INSERT INTO bdgd.layer SELECT ... ON CONFLICT     │
  │   4. COMMIT transacional                               │
  └───────────────────────────┬────────────────────────────┘
                              │
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │       Cleanup Automático & Registro de Idempotência    │
  │   - Remoção imediata dos GeoParquet / Staging TSV      │
  │   - Hash SHA-256 + camada salvos em bdgd._etl_state    │
  │   - Liberação de memória entre camadas (gc.collect)    │
  └────────────────────────────────────────────────────────┘
```

---

## 📋 Requisitos Obrigatórios Atendidos

1. **Leitura direta do ZIP via GDAL `/vsizip/`**: Não extrai o `.gdb` em disco.
2. **Descoberta automática de todas as layers**: Lista dinamicamente as feições via GDAL/PyOGRio. Não há hardcode de camadas.
3. **Processamento camada a camada**: Libera a memória explicitamente após cada camada (`gc.collect()`).
4. **Paralelização por camada**: Orquestrado via `concurrent.futures.ProcessPoolExecutor` com nº de workers configurável (`-w`).
5. **Conversão intermediária para GeoParquet**: Gravado em formato nativo Parquet por camada antes da transformação.
6. **Transformações espaciais via DuckDB + spatial extension**: Reprojeção (`ST_Transform`), validação e geração de chave executados no DuckDB sem loops em Pandas.
7. **Carga final por Bulk Load**: `COPY FROM STDIN` no PostgreSQL com tabela temporária de staging e upsert set-based (`ON CONFLICT (asset_key) DO UPDATE`). Nunca ORM ou insert linha a linha.
8. **Idempotência por Hash SHA-256**: Calcula o digest do ZIP + camada. Pula automaticamente camadas já processadas e sem alteração (use `--force` para reprocessar).
9. **Logging Estruturado e Telemetria**: Medição de pico de RAM (`tracemalloc`/`psutil`), tempo de execução e contagem de feições, com tabela resumo e flag `--json`.
10. **Isolamento de Erro por Camada**: Falha em uma camada não derruba o pipeline; registra erro no resumo e segue para as próximas.
11. **Cleanup Automático**: Remove arquivos temporários de staging e Parquet logo após a confirmação da transação no banco.
12. **Configuração via TOML/CLI**: Suporta arquivo `config.toml`, variáveis de ambiente e sobrescrita completa via linha de comando.

---

## 📦 Dependências de Sistema: `libgdal`

O pipeline utiliza bindings C do GDAL para leitura de `/vsizip/` e do driver `OpenFileGDB`:

| Dependência | Versão Mínima | Versão Recomendada |
| :--- | :---: | :---: |
| **libgdal** | `>= 3.4` | `3.9.x` ou `>= 3.10` |
| **PROJ** | `>= 8.0` | `>= 9.0` |
| **Python** | `>= 3.11` | `3.11`, `3.12` ou `3.13` |

### Instalação da `libgdal` no Sistema Operacional (fora do venv):

- **Ubuntu / Debian:**
  ```bash
  sudo apt-get update
  sudo apt-get install -y gdal-bin libgdal-dev
  ```
- **Fedora / RHEL:**
  ```bash
  sudo dnf install -y gdal gdal-devel
  ```
- **Windows:**
  - Instalar via **OSGeo4W**: [https://trac.osgeo.org/osgeo4w/](https://trac.osgeo.org/osgeo4w/)
  - Ou utilizar **conda / mamba**:
    ```bash
    conda create -n bdgd_env -c conda-forge python=3.13 gdal pyogrio fiona duckdb psycopg2
    ```
- **macOS (Homebrew):**
  ```bash
  brew install gdal
  ```

---

## 🚀 Como Executar

### 1. Instalar Dependências do Python

Usando `pip`:
```bash
pip install -r requirements.txt
```

Ou usando `poetry`:
```bash
poetry install
```

### 2. Configurar o Banco de Dados

Defina a URL de conexão via `.env` ou variável de ambiente:
```bash
export BDGD_DB_URL="postgresql://postgres:123@localhost:5432/bdgd"
```

### 3. Execução via Linha de Comando (CLI)

#### Processar Todas as Camadas do ZIP (Automático com 4 workers):
```bash
python main.py "/caminho/para/distribuidora.gdb.zip" EDP_SP SUDESTE -w 4
```

#### Processar Subconjunto Específico de Camadas:
```bash
python main.py "/caminho/para/distribuidora.gdb.zip" EDP_SP SUDESTE --layers SSDAT SUB POSTE UCBT -w 4
```

#### Forçar Reprocessamento (Ignorar Idempotência):
```bash
python main.py "/caminho/para/distribuidora.gdb.zip" EDP_SP SUDESTE --force
```

#### Executar usando Arquivo de Configuração `config.toml`:
```bash
python main.py -c config.toml
```

#### Saída Estruturada JSON (para integração com n8n, CloudWatch ou ELK):
```bash
python main.py "/caminho/para/distribuidora.gdb.zip" EDP_SP SUDESTE --json
```

### 4. Executar Benchmark Comparativo
```bash
python benchmark.py
```

### 5. Executar os Testes Automatizados
```bash
python -m pytest tests/
```