package com.backend.tecsys.bdgd.repository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;

@Slf4j
@Component
@RequiredArgsConstructor
public class BdgdImportTableInitializer {
    private final JdbcTemplate jdbc;

    @PostConstruct
    void createTable() {
        jdbc.execute("CREATE SCHEMA IF NOT EXISTS bdgd");
        jdbc.execute("CREATE TABLE IF NOT EXISTS bdgd_imports (id VARCHAR(36) PRIMARY KEY, distribuidora VARCHAR(120) NOT NULL, regiao VARCHAR(120) NOT NULL, data_referencia DATE NOT NULL, file_name VARCHAR(255) NOT NULL, storage_key VARCHAR(500) NOT NULL, status VARCHAR(30) NOT NULL, error_message VARCHAR(1000), created_at TIMESTAMP NOT NULL)");

        String[] assetTables = {"poste", "sub", "ucbt", "ucmt", "ssdbt", "ssdmt", "ssdat"};
        for (String table : assetTables) {
            // ALTER TABLE exige lock exclusivo mesmo com IF NOT EXISTS e fica preso atras de consultas longas,
            // bloqueando a tabela inteira. So executa se a coluna realmente nao existir.
            if (!columnExists(table, "importacao_id")) {
                jdbc.execute("ALTER TABLE IF EXISTS bdgd." + table + " ADD COLUMN IF NOT EXISTS importacao_id VARCHAR(36)");
            }
            Boolean exists = jdbc.queryForObject(
                    "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'bdgd' AND table_name = ?)",
                    Boolean.class, table);
            if (Boolean.TRUE.equals(exists) && !indexExists("idx_" + table + "_importacao_id")) {
                jdbc.execute("CREATE INDEX IF NOT EXISTS idx_" + table + "_importacao_id ON bdgd." + table + " (importacao_id)");
            }
        }

        try {
            jdbc.update("""
                    UPDATE bdgd_imports
                    SET data_referencia = substring(file_name FROM '(20[0-9]{2}-[0-9]{2}-[0-9]{2})')::date
                    WHERE upper(distribuidora) = 'CHESP'
                      AND file_name ~ '(20[0-9]{2}-[0-9]{2}-[0-9]{2})'
                    """);
        } catch (Exception ignored) {
            // Em ambientes sem suporte à sintaxe regex/cast do Postgres (ex: H2 em memória nos testes), ignora a migração legada
        }
    }

    private boolean columnExists(String table, String column) {
        try {
            return Boolean.TRUE.equals(jdbc.queryForObject(
                    "SELECT EXISTS (SELECT 1 FROM information_schema.columns "
                            + "WHERE table_schema = 'bdgd' AND table_name = ? AND column_name = ?)",
                    Boolean.class, table, column));
        } catch (Exception e) {
            return false;
        }
    }

    private boolean indexExists(String indexName) {
        try {
            return Boolean.TRUE.equals(jdbc.queryForObject(
                    "SELECT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = 'bdgd' AND indexname = ?)",
                    Boolean.class, indexName));
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Indices por (distribuidora, regiao): as consultas de listagem, contorno e busca filtram por esse par
     * e, sem indice, varrem as tabelas inteiras. Criados em segundo plano e com CONCURRENTLY, para nao
     * atrasar a subida nem bloquear escritas (ETL) no banco compartilhado. So roda em PostgreSQL.
     */
    @EventListener(ApplicationReadyEvent.class)
    void createGroupingIndexesInBackground() {
        Thread worker = new Thread(() -> {
            try {
                String version = jdbc.queryForObject("SELECT version()", String.class);
                if (version == null || !version.contains("PostgreSQL")) {
                    return;
                }
                for (String table : new String[] {"poste", "sub", "ucbt", "ucmt", "ssdbt", "ssdmt", "ssdat"}) {
                    String indexName = "idx_" + table + "_dist_regiao";
                    Boolean tableExists = jdbc.queryForObject(
                            "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'bdgd' AND table_name = ?)",
                            Boolean.class, table);
                    if (!Boolean.TRUE.equals(tableExists) || indexExists(indexName)) {
                        continue;
                    }
                    try {
                        log.info("Criando indice {} em segundo plano...", indexName);
                        jdbc.execute("CREATE INDEX CONCURRENTLY IF NOT EXISTS " + indexName
                                + " ON bdgd." + table + " (distribuidora, regiao)");
                        log.info("Indice {} criado.", indexName);
                    } catch (Exception e) {
                        log.warn("Nao foi possivel criar o indice {}: {}", indexName, e.getMessage());
                    }
                }
            } catch (Exception e) {
                log.warn("Criacao de indices em segundo plano ignorada: {}", e.getMessage());
            }
        }, "bdgd-index-builder");
        worker.setDaemon(true);
        worker.start();
    }
}
