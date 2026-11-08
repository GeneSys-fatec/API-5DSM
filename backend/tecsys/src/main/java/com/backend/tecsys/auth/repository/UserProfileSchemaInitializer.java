package com.backend.tecsys.auth.repository;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
@Profile("!mock")
@RequiredArgsConstructor
public class UserProfileSchemaInitializer {
    private final JdbcTemplate jdbcTemplate;

    @PostConstruct
    void initializeUserSchema() {
        jdbcTemplate.execute("CREATE SCHEMA IF NOT EXISTS app");

        jdbcTemplate.execute("""
            CREATE TABLE IF NOT EXISTS app.distribuidora (
                id BIGSERIAL PRIMARY KEY,
                nome TEXT NOT NULL,
                sigla TEXT NOT NULL UNIQUE
            )
        """);

        jdbcTemplate.execute("""
            CREATE TABLE IF NOT EXISTS app.usuario (
                id BIGSERIAL PRIMARY KEY,
                nome TEXT NOT NULL,
                email TEXT NOT NULL UNIQUE,
                avatar_url VARCHAR(1000),
                senha_hash TEXT NOT NULL,
                papel TEXT NOT NULL DEFAULT 'engenheiro',
                distribuidora_id BIGINT,
                criado_em TIMESTAMPTZ NOT NULL DEFAULT now()
            )
        """);

        jdbcTemplate.execute("ALTER TABLE app.usuario ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(1000)");

        jdbcTemplate.execute("""
            CREATE TABLE IF NOT EXISTS app.refresh_token (
                id BIGSERIAL PRIMARY KEY,
                usuario_id BIGINT NOT NULL REFERENCES app.usuario(id) ON DELETE CASCADE,
                token_hash TEXT NOT NULL UNIQUE,
                expira_em TIMESTAMPTZ NOT NULL,
                revogado BOOLEAN NOT NULL DEFAULT false,
                criado_em TIMESTAMPTZ NOT NULL DEFAULT now()
            )
        """);

        jdbcTemplate.execute("""
            INSERT INTO app.usuario (nome, email, avatar_url, senha_hash, papel, distribuidora_id)
            VALUES (
                'Administrador Tecsys',
                'admin@tecsys.com',
                NULL,
                '$2a$10$to.TrijT0G.k6sg2Op3pFubVG//r54MwJBP4whsPG7oGc24USOrdy',
                'admin',
                NULL
            )
            ON CONFLICT (email) DO NOTHING
        """);
    }
}
