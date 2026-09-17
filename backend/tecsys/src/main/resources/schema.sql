-- =====================================================================
-- Modelagem de dados completa
-- Desafio Tecsys: Planejamento de Cobertura de RF em redes de sensores
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE SCHEMA IF NOT EXISTS app;
CREATE SCHEMA IF NOT EXISTS bdgd;

-- ---------------------------------------------------------------------
-- app.distribuidora: entidade central de multi-tenant.
-- Todo o resto (usuário, importação, ativo, cenário) referencia isso.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.distribuidora (
    id      BIGSERIAL PRIMARY KEY,
    nome    TEXT NOT NULL,
    sigla   TEXT NOT NULL UNIQUE
);

-- ---------------------------------------------------------------------
-- bdgd.importacao: controle de cada upload/processamento de BDGD (SYS-6/14).
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bdgd.importacao (
    id               BIGSERIAL PRIMARY KEY,
    distribuidora_id BIGINT NOT NULL REFERENCES app.distribuidora(id),
    regiao           TEXT,
    gdb_s3_path      TEXT NOT NULL,
    status           TEXT NOT NULL DEFAULT 'processando'
                         CHECK (status IN ('processando', 'concluido', 'erro')),
    layers_status    JSONB NOT NULL DEFAULT '{}',
    erro_detalhe     TEXT,
    iniciado_em      TIMESTAMPTZ NOT NULL DEFAULT now(),
    concluido_em     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS importacao_distribuidora_idx ON bdgd.importacao (distribuidora_id);

-- ---------------------------------------------------------------------
-- bdgd.ativo: todos os ativos elétricos da BDGD numa tabela só,
-- discriminados por tipo_ativo (POSTE, SUB, UCBT, UCMT, SSDMT...).
-- ativo_key é a chave estável gerada no ETL (SYS-20), garante idempotência.
-- atributos guarda o que não é modelado explicitamente (varia por tipo).
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bdgd.ativo (
    ativo_key        TEXT PRIMARY KEY,
    distribuidora_id BIGINT NOT NULL REFERENCES app.distribuidora(id),
    tipo_ativo       TEXT NOT NULL,
    atributos        JSONB NOT NULL DEFAULT '{}',
    geom             geometry(Geometry, 4326) NOT NULL,
    importacao_id    BIGINT REFERENCES bdgd.importacao(id),
    criado_em        TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ativo_geom_idx ON bdgd.ativo USING GIST (geom);
CREATE INDEX IF NOT EXISTS ativo_distribuidora_tipo_idx ON bdgd.ativo (distribuidora_id, tipo_ativo);

-- ---------------------------------------------------------------------
-- app.usuario: login vinculado a uma distribuidora (isolamento de dados).
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.usuario (
    id               BIGSERIAL PRIMARY KEY,
    nome             TEXT NOT NULL,
    email            TEXT NOT NULL UNIQUE,
    senha_hash       TEXT NOT NULL,
    papel            TEXT NOT NULL DEFAULT 'engenheiro'
                         CHECK (papel IN ('engenheiro', 'gestor', 'admin')),
    distribuidora_id BIGINT NOT NULL REFERENCES app.distribuidora(id),
    criado_em        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS usuario_distribuidora_idx ON app.usuario (distribuidora_id);

-- ---------------------------------------------------------------------
-- app.refresh_token: tokens de refresh da autenticação JWT (SYS-4).
-- Guardar isso permite revogar sessão sem esperar o token expirar.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.refresh_token (
    id          BIGSERIAL PRIMARY KEY,
    usuario_id  BIGINT NOT NULL REFERENCES app.usuario(id) ON DELETE CASCADE,
    token_hash  TEXT NOT NULL UNIQUE,
    expira_em   TIMESTAMPTZ NOT NULL,
    revogado    BOOLEAN NOT NULL DEFAULT false,
    criado_em   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS refresh_token_usuario_idx ON app.refresh_token (usuario_id);

-- ---------------------------------------------------------------------
-- app.parametro_rf: modelo de propagação parametrizável, reaproveitável
-- entre cenários.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.parametro_rf (
    id                  BIGSERIAL PRIMARY KEY,
    nome                TEXT NOT NULL,
    modelo_propagacao   TEXT NOT NULL DEFAULT 'raio_fixo'
                             CHECK (modelo_propagacao IN ('raio_fixo', 'hata', 'log_distance')),
    frequencia_mhz      NUMERIC,
    potencia_dbm        NUMERIC,
    altura_antena_m     NUMERIC,
    raio_cobertura_m    NUMERIC,
    criado_por          BIGINT REFERENCES app.usuario(id),
    criado_em           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- app.candidato_gateway: pool de locais candidatos a gateway, vindos da
-- BDGD (postes/subestações) ou cadastrados manualmente. Reaproveitável
-- entre cenários da mesma distribuidora/região.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.candidato_gateway (
    id               BIGSERIAL PRIMARY KEY,
    origem           TEXT NOT NULL CHECK (origem IN ('bdgd', 'manual')),
    ativo_key        TEXT REFERENCES bdgd.ativo(ativo_key),
    distribuidora_id BIGINT NOT NULL REFERENCES app.distribuidora(id),
    geom             geometry(Point, 4326) NOT NULL,
    custo_estimado   NUMERIC,
    criado_por       BIGINT REFERENCES app.usuario(id),
    criado_em        TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (origem != 'bdgd' OR ativo_key IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS candidato_gateway_geom_idx ON app.candidato_gateway USING GIST (geom);
CREATE INDEX IF NOT EXISTS candidato_gateway_distribuidora_idx ON app.candidato_gateway (distribuidora_id);

-- ---------------------------------------------------------------------
-- app.cenario: configuração de uma simulação (área, meta, limite de
-- gateways, custo unitário, parâmetros de RF usados).
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.cenario (
    id                      BIGSERIAL PRIMARY KEY,
    nome                    TEXT NOT NULL,
    usuario_id              BIGINT NOT NULL REFERENCES app.usuario(id),
    distribuidora_id        BIGINT NOT NULL REFERENCES app.distribuidora(id),
    regiao_nome             TEXT,
    area_geom               geometry(Polygon, 4326) NOT NULL,
    meta_cobertura_pct      NUMERIC NOT NULL,
    max_gateways            INTEGER NOT NULL,
    custo_unitario_gateway  NUMERIC,
    parametro_rf_id         BIGINT REFERENCES app.parametro_rf(id),
    status                  TEXT NOT NULL DEFAULT 'rascunho'
                                 CHECK (status IN ('rascunho', 'processando', 'concluido', 'erro')),
    criado_em               TIMESTAMPTZ NOT NULL DEFAULT now(),
    processado_em           TIMESTAMPTZ,
    tempo_processamento_ms  INTEGER
);

CREATE INDEX IF NOT EXISTS cenario_area_geom_idx ON app.cenario USING GIST (area_geom);
CREATE INDEX IF NOT EXISTS cenario_usuario_idx ON app.cenario (usuario_id);
CREATE INDEX IF NOT EXISTS cenario_distribuidora_regiao_idx ON app.cenario (distribuidora_id, regiao_nome);

-- ---------------------------------------------------------------------
-- app.cenario_gateway_selecionado: quais candidatos o algoritmo escolheu
-- num cenário, e se o usuário ajustou a posição manualmente depois.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.cenario_gateway_selecionado (
    id                    BIGSERIAL PRIMARY KEY,
    cenario_id            BIGINT NOT NULL REFERENCES app.cenario(id) ON DELETE CASCADE,
    candidato_gateway_id  BIGINT NOT NULL REFERENCES app.candidato_gateway(id),
    geom_final            geometry(Point, 4326) NOT NULL,
    ajustado_manualmente  BOOLEAN NOT NULL DEFAULT false,

    UNIQUE (cenario_id, candidato_gateway_id)
);

CREATE INDEX IF NOT EXISTS cenario_gateway_geom_idx ON app.cenario_gateway_selecionado USING GIST (geom_final);

-- ---------------------------------------------------------------------
-- app.cenario_cobertura_ativo: status de cobertura de cada ativo dentro
-- de um cenário específico. Base para os indicadores e pra exportação
-- em GeoJSON.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.cenario_cobertura_ativo (
    id                       BIGSERIAL PRIMARY KEY,
    cenario_id               BIGINT NOT NULL REFERENCES app.cenario(id) ON DELETE CASCADE,
    ativo_key                TEXT NOT NULL REFERENCES bdgd.ativo(ativo_key),
    coberto                  BOOLEAN NOT NULL,
    gateway_selecionado_id   BIGINT REFERENCES app.cenario_gateway_selecionado(id),

    UNIQUE (cenario_id, ativo_key)
);

CREATE INDEX IF NOT EXISTS cobertura_ativo_cenario_idx ON app.cenario_cobertura_ativo (cenario_id);

-- ---------------------------------------------------------------------
-- app.cenario_indicador: resultado final desnormalizado (1 linha por
-- cenário), pra dashboard ler direto sem recalcular nada.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.cenario_indicador (
    cenario_id               BIGINT PRIMARY KEY REFERENCES app.cenario(id) ON DELETE CASCADE,
    pct_cobertura_total      NUMERIC NOT NULL,
    pct_cobertura_por_tipo   JSONB NOT NULL DEFAULT '{}',
    qtd_gateways_utilizados  INTEGER NOT NULL,
    custo_total_estimado     NUMERIC,
    tempo_processamento_ms   INTEGER,
    meta_atingida            BOOLEAN NOT NULL,
    calculado_em             TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- app.relatorio_exportado: histórico de exports (PDF, GeoJSON, CSV).
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.relatorio_exportado (
    id              BIGSERIAL PRIMARY KEY,
    cenario_id      BIGINT NOT NULL REFERENCES app.cenario(id) ON DELETE CASCADE,
    formato         TEXT NOT NULL CHECK (formato IN ('pdf', 'geojson', 'csv')),
    arquivo_s3_path TEXT NOT NULL,
    gerado_por      BIGINT REFERENCES app.usuario(id),
    gerado_em       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS relatorio_cenario_idx ON app.relatorio_exportado (cenario_id);

-- ---------------------------------------------------------------------
-- app.notificacao: aviso de processamento concluído / meta não atingida.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app.notificacao (
    id          BIGSERIAL PRIMARY KEY,
    usuario_id  BIGINT NOT NULL REFERENCES app.usuario(id),
    cenario_id  BIGINT REFERENCES app.cenario(id) ON DELETE CASCADE,
    tipo        TEXT NOT NULL CHECK (tipo IN ('processamento_concluido', 'meta_nao_atingida')),
    lida        BOOLEAN NOT NULL DEFAULT false,
    criado_em   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS notificacao_usuario_nao_lida_idx ON app.notificacao (usuario_id) WHERE NOT lida;

-- ---------------------------------------------------------------------
-- Carga inicial para desenvolvimento (distribuidora e usuário admin)
-- ---------------------------------------------------------------------
INSERT INTO app.distribuidora (id, nome, sigla)
VALUES (1, 'Tecsys Energia', 'TECSYS')
ON CONFLICT (sigla) DO NOTHING;

INSERT INTO app.usuario (nome, email, senha_hash, papel, distribuidora_id)
VALUES (
    'Administrador Tecsys',
    'admin@tecsys.com',
    '$2a$10$to.TrijT0G.k6sg2Op3pFubVG//r54MwJBP4whsPG7oGc24USOrdy', -- Senha: Admin@123
    'admin',
    (SELECT id FROM app.distribuidora WHERE sigla = 'TECSYS' LIMIT 1)
)
ON CONFLICT (email) DO NOTHING;
