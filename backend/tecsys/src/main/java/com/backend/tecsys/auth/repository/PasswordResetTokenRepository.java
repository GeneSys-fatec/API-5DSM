package com.backend.tecsys.auth.repository;

import com.backend.tecsys.auth.model.PasswordResetToken;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Repositório de tokens de recuperação de senha.
 * No perfil mock mantém os tokens em memória; em postgres persiste em
 * app.password_reset_token (criada pelo PasswordResetSchemaInitializer).
 */
@Repository
@RequiredArgsConstructor
public class PasswordResetTokenRepository {

    @Autowired(required = false)
    private final JdbcTemplate jdbcTemplate;

    private final Environment environment;

    // cache em memória usado tanto pelo perfil mock quanto como fallback
    private final Map<String, Long> inMemoryTokens = new ConcurrentHashMap<>();

    private boolean isMock() {
        return Arrays.asList(environment.getActiveProfiles()).contains("mock");
    }

    // ------------------------------------------------------------------ //

    public void save(String tokenHash, Long usuarioId, int expiracaoMinutos) {
        inMemoryTokens.put(tokenHash, usuarioId);

        if (!isMock() && jdbcTemplate != null) {
            try {
                jdbcTemplate.update(
                    "INSERT INTO app.password_reset_token (usuario_id, token_hash, expira_em, usado) VALUES (?, ?, ?, false)",
                    usuarioId,
                    tokenHash,
                    Timestamp.from(Instant.now().plus(expiracaoMinutos, ChronoUnit.MINUTES))
                );
            } catch (Exception ignored) {}
        }
    }

    public Optional<Long> findUsuarioIdByTokenHash(String tokenHash) {
        if (!isMock() && jdbcTemplate != null) {
            try {
                Long id = jdbcTemplate.queryForObject(
                    "SELECT usuario_id FROM app.password_reset_token WHERE token_hash = ? AND usado = false AND expira_em > now()",
                    Long.class,
                    tokenHash
                );
                return Optional.ofNullable(id);
            } catch (Exception e) {
                return Optional.empty();
            }
        }
        return Optional.ofNullable(inMemoryTokens.get(tokenHash));
    }

    public void markAsUsed(String tokenHash) {
        inMemoryTokens.remove(tokenHash);

        if (!isMock() && jdbcTemplate != null) {
            try {
                jdbcTemplate.update(
                    "UPDATE app.password_reset_token SET usado = true WHERE token_hash = ?",
                    tokenHash
                );
            } catch (Exception ignored) {}
        }
    }

    /** Remove tokens antigos/expirados para higiene (chamado periodicamente). */
    public void deleteExpiredTokens() {
        if (!isMock() && jdbcTemplate != null) {
            try {
                jdbcTemplate.update(
                    "DELETE FROM app.password_reset_token WHERE expira_em < now() OR usado = true"
                );
            } catch (Exception ignored) {}
        }
    }
}
