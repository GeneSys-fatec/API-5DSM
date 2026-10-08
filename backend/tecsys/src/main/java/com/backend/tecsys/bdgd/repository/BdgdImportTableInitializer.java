package com.backend.tecsys.bdgd.repository;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;

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
            jdbc.execute("ALTER TABLE IF EXISTS bdgd." + table + " ADD COLUMN IF NOT EXISTS importacao_id VARCHAR(36)");
            Boolean exists = jdbc.queryForObject(
                    "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'bdgd' AND table_name = ?)",
                    Boolean.class, table);
            if (Boolean.TRUE.equals(exists)) {
                jdbc.execute("CREATE INDEX IF NOT EXISTS idx_" + table + "_importacao_id ON bdgd." + table + " (importacao_id)");
            }
        }

        jdbc.update("""
                UPDATE bdgd_imports
                SET data_referencia = substring(file_name FROM '(20[0-9]{2}-[0-9]{2}-[0-9]{2})')::date
                WHERE upper(distribuidora) = 'CHESP'
                  AND file_name ~ '(20[0-9]{2}-[0-9]{2}-[0-9]{2})'
                """);
    }
}
