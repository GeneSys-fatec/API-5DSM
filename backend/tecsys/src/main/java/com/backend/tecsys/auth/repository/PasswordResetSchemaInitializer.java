package com.backend.tecsys.auth.repository;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Cria a tabela app.password_reset_token no banco na subida do backend
 * (apenas no perfil postgres/non-mock).
 */
@Component
@Profile("!mock")
@RequiredArgsConstructor
public class PasswordResetSchemaInitializer {

    private final JdbcTemplate jdbcTemplate;

    @PostConstruct
    void init() {
        jdbcTemplate.execute("""
            CREATE TABLE IF NOT EXISTS app.password_reset_token (
                id           BIGSERIAL PRIMARY KEY,
                usuario_id   BIGINT NOT NULL REFERENCES app.usuario(id) ON DELETE CASCADE,
                token_hash   TEXT NOT NULL UNIQUE,
                expira_em    TIMESTAMPTZ NOT NULL,
                usado        BOOLEAN NOT NULL DEFAULT false,
                criado_em    TIMESTAMPTZ NOT NULL DEFAULT now()
            )
        """);

        // índice para busca rápida por hash
        try {
            jdbcTemplate.execute(
                "CREATE INDEX IF NOT EXISTS idx_prt_token_hash ON app.password_reset_token (token_hash)"
            );
        } catch (Exception ignored) {}
    }
}
