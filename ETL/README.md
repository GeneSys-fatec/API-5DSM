# ETL BDGD — Pipeline de Importação para PostGIS

Pipeline Python que lê um arquivo `.gdb` da BDGD (Base de Dados Geográfica da
Distribuidora — ANEEL), transforma os dados e faz upsert idempotente no PostGIS.

---

## Estrutura

```
ETL/
├── config.py        # Configurações centralizadas (DB, CRS, layers, campos chave)
├── extract.py       # Leitura do .gdb com fiona/geopandas
├── transform.py     # Reprojeção, correção de geometria, deduplicação, chave estável
├── load.py          # Upsert PostGIS com ON CONFLICT + índice GiST
├── main.py          # Orquestrador: loop por layer com resiliência a falhas
└── requirements.txt # Dependências Python
```

---

## Pré-requisitos

| Requisito | Versão mínima |
|-----------|--------------|
| Python    | 3.10         |
| PostgreSQL + PostGIS | 14 + 3.x |
| GDAL/Fiona (OpenFileGDB driver) | GDAL ≥ 3.5 |

### Instalar dependências

```bash
pip install -r requirements.txt
```

> **Dica para Windows:** instalar `geopandas` e `fiona` via pip pode falhar se
> o GDAL não estiver no PATH. A forma mais confiável é usar o instalador
> **OSGeo4W** ou instalar com `conda`:
> ```bash
> conda install -c conda-forge geopandas fiona pyproj shapely
> ```

---

## Configuração

### Variável de ambiente

```bash
export BDGD_DB_URL="postgresql://usuario:senha@host:5432/nome_banco"
```

Ou crie um arquivo `.env` na pasta `ETL/`:

```ini
BDGD_DB_URL=postgresql://postgres:postgres@localhost:5432/bdgd
```

### Ajustes em `config.py`

| Variável | Default | Descrição |
|----------|---------|-----------|
| `SCHEMA` | `"bdgd"` | Schema PostgreSQL onde as tabelas serão criadas |
| `TARGET_CRS` | `"EPSG:4326"` | CRS de destino (WGS 84) |
| `SOURCE_CRS_FALLBACK` | `"EPSG:4674"` | SIRGAS 2000 — padrão ANEEL se o CRS não vier no GDB |
| `LAYERS` | `["POSTE", "SUB", "UCBT", "UCMT", "SSDMT"]` | Layers a importar |
| `KEY_COLUMN_BY_LAYER` | `{layer: "COD_ID"}` | Campo chave por layer (DDA ANEEL) |

---

## Uso

```bash
python main.py <CAMINHO.GDB> <NOME_DISTRIBUIDORA>
```

### Exemplos

```bash
# Importação completa
python main.py /dados/CEMIG_2023.gdb CEMIG

# Apenas algumas layers
python main.py /dados/CEMIG_2023.gdb CEMIG --layers POSTE SUB

# Connection string diferente do .env
python main.py /dados/CEMIG_2023.gdb CEMIG --db-url postgresql://admin:pass@db:5432/energia

# Log mais detalhado
python main.py /dados/CEMIG_2023.gdb CEMIG --log-level DEBUG
```

### Saída esperada

```
LAYER      LINHAS   TEMPO(s)  STATUS
--------------------------------------------------------------------------
POSTE       15420       8.34  OK
SUB            48       0.21  OK
UCBT       230100      42.18  OK
UCMT          893       1.05  OK
SSDMT        1204       1.73  OK
--------------------------------------------------------------------------
TOTAL      247665      53.51  CONCLUÍDO
```

---

## Critérios de aceite (SYS-14)

### 1. Verificar layers disponíveis no GDB

```python
import fiona
print(fiona.listlayers("seu_arquivo.gdb"))
```

O pipeline loga automaticamente as layers encontradas e as compara com
`config.LAYERS` a cada execução.

### 2. Confirmar campo chave por layer

Se `COD_ID` não existir numa layer, o pipeline tenta `FID` e loga um aviso.
Para sobrescrever, edite `KEY_COLUMN_BY_LAYER` em `config.py`:

```python
KEY_COLUMN_BY_LAYER = {
    "POSTE": "COD_ID",
    "SUB":   "COD_ID",     # ajuste aqui se o nome real for diferente
    ...
}
```

### 3. CRS ausente

Se o GDB não reportar CRS, o pipeline assume `EPSG:4674` (SIRGAS 2000) com
aviso explícito no log. Para usar outro CRS de origem, altere
`SOURCE_CRS_FALLBACK` em `config.py`.

### 4. Tabelas criadas com índice GiST

Após a primeira execução, verifique no psql:

```sql
\d bdgd.poste
-- Deve mostrar: Index "idx_poste_geometry" (GIST) e "uq_poste_asset_key" (UNIQUE)
```

### 5. Idempotência (segunda rodada não duplica)

```bash
python main.py seu.gdb DIST   # 1ª execução
python main.py seu.gdb DIST   # 2ª execução — mesma contagem de linhas

# Verificar no banco:
# SELECT count(*) FROM bdgd.poste;  -- deve ser igual nas duas rodadas
```

### 6. Resiliência a falha isolada

Para testar, renomeie temporariamente o campo chave numa layer:

```python
# teste_resiliencia.py
import geopandas as gpd, fiona

gdb = "seu.gdb"
gdf = gpd.read_file(gdb, layer="POSTE")
gdf = gdf.rename(columns={"COD_ID": "COD_ID_BACKUP"})
# Salva como shapefile temporário e rode o pipeline apontando pra ele
```

O pipeline deve reportar `ERRO` apenas na layer afetada e continuar as demais.

---

## Tabelas geradas no PostGIS

| Tabela | Schema | Layer origem |
|--------|--------|-------------|
| `poste` | `bdgd` | POSTE |
| `sub` | `bdgd` | SUB |
| `ucbt` | `bdgd` | UCBT |
| `ucmt` | `bdgd` | UCMT |
| `ssdmt` | `bdgd` | SSDMT |

Cada tabela inclui:
- Todas as colunas originais do GDB
- `geometry` (GEOMETRY, SRID=4326)
- `asset_key` (TEXT, UNIQUE) — chave estável `"<LAYER>::<COD_ID>"`
- `distribuidora` (TEXT) — nome passado na linha de comando

---

## Verificação no QGIS

1. Abra o QGIS e adicione uma conexão PostGIS para o banco `bdgd`
2. Adicione também o arquivo `.gdb` original
3. Compare as camadas lado a lado — geometrias e contagens devem coincidir
