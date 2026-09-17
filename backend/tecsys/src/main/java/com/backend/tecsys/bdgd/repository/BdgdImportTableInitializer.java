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
        jdbc.execute("CREATE TABLE IF NOT EXISTS bdgd_imports (id VARCHAR(36) PRIMARY KEY, distribuidora VARCHAR(120) NOT NULL, regiao VARCHAR(120) NOT NULL, data_referencia DATE NOT NULL, file_name VARCHAR(255) NOT NULL, storage_key VARCHAR(500) NOT NULL, status VARCHAR(30) NOT NULL, error_message VARCHAR(1000), created_at TIMESTAMP NOT NULL)");
    }
}
