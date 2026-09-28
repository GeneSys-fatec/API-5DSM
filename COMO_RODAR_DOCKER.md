# Como rodar o projeto com Docker

## Pre-requisito

Docker Desktop instalado e rodando.

## 1. Configurar o .env

```powershell
cp .env.example .env
```

Os valores default ja funcionam localmente. Nao precisa editar nada pra rodar local.

## 2. Subir banco + backend + adminer

```powershell
docker compose -f docker-compose.dev.yml up -d
```

Sobe 3 containers:
- bdgd_postgis_dev - Postgres/PostGIS, porta 5432
- bdgd_backend_dev - Spring Boot, porta 8080
- bdgd_adminer_dev - interface web do banco, porta 8082

O etl nao sobe com esse comando (roda pontualmente, ver passo 4).

## 3. Verificar se subiu certo

```powershell
docker compose -f docker-compose.dev.yml ps
```

Todos devem estar Up/healthy. Testar:
- Backend: http://localhost:8080
- Adminer: http://localhost:8082 (Sistema: PostgreSQL, Servidor: postgis_dev, usuario/senha/base conforme o .env)

## 4. Rodar o ETL com um arquivo .gdb

Builda a imagem do ETL (so na primeira vez ou quando o codigo mudar):

```powershell
docker compose -f docker-compose.dev.yml --profile etl build etl
```

Monta a pasta com o .gdb como volume e roda o pipeline:

```powershell
docker compose -f docker-compose.dev.yml --profile etl run --rm `
  -v "C:\caminho\para\pasta\com\gdb:/data" `
  etl python main.py /data/nome_do_arquivo.gdb DISTRIBUIDORA REGIAO
```

Exemplo real:

```powershell
docker compose -f docker-compose.dev.yml --profile etl run --rm `
  -v "C:\Users\issam\Downloads\bdgd:/data" `
  etl python main.py /data/BDGD_CEMIG.gdb CEMIG SUDESTE
```

Argumentos: <caminho.gdb> <distribuidora> <regiao>. Opcionais: --layers LAYER1 LAYER2 (processa so essas layers) e --log-level DEBUG (mais detalhe nos logs).

Se der certo, os dados aparecem nas tabelas bdgd.* - confira no Adminer.

## 5. Rodar os testes automatizados do ETL (sem precisar de .gdb)

```powershell
docker compose -f docker-compose.dev.yml --profile etl run --rm etl python3 -m pytest tests/ -v
```

## 6. Derrubar o ambiente

Preservando os dados:
```powershell
docker compose -f docker-compose.dev.yml down
```

Apagando os dados tambem:
```powershell
docker compose -f docker-compose.dev.yml down -v
```

## Observacoes

- docker-compose.dev.yml (raiz) e o ambiente de desenvolvimento persistente. E diferente de ETL/docker-compose.test.yml, que e so pra suite de testes automatizados (portas 55432/8081, efemero). Os dois nao conflitam.
- Nunca commitar o .env real (ja esta no .gitignore).
- Pra apontar pro banco da AWS em vez do Postgres local, sobrescreva BDGD_DB_URL/SPRING_DATASOURCE_URL* no .env - nada mais precisa mudar.