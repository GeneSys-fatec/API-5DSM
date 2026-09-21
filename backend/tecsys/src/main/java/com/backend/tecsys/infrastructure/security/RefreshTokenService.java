package com.backend.tecsys.infrastructure.security;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class RefreshTokenService {

    private final Map<String, Long> activeTokens = new ConcurrentHashMap<>();
    private final JdbcTemplate jdbcTemplate;
    private final boolean isMock;

    public RefreshTokenService(
            @Autowired(required = false) JdbcTemplate jdbcTemplate,
            Environment environment) {
        this.jdbcTemplate = jdbcTemplate;
        this.isMock = Arrays.asList(environment.getActiveProfiles()).contains("mock");
    }

    public void save(String refreshToken, Long userId) {
        if (refreshToken == null || userId == null) return;

        String hashed = hashToken(refreshToken);
        activeTokens.put(hashed, userId);

        if (!isMock && jdbcTemplate != null) {
            try {
                String sql = "INSERT INTO app.refresh_token (usuario_id, token_hash, expira_em, revogado) VALUES (?, ?, ?, false)";
                Timestamp expiraEm = Timestamp.from(Instant.now().plus(7, ChronoUnit.DAYS));
                jdbcTemplate.update(sql, userId, hashed, expiraEm);
            } catch (Exception ignored) {
            }
        }
    }

    public boolean isValid(String refreshToken) {
        if (refreshToken == null) return false;

        String hashed = hashToken(refreshToken);
        if (!isMock && jdbcTemplate != null) {
            try {
                String sql = "SELECT count(1) FROM app.refresh_token WHERE token_hash = ? AND revogado = false AND expira_em > now()";
                Integer count = jdbcTemplate.queryForObject(sql, Integer.class, hashed);
                if (count != null && count > 0) {
                    return true;
                }
            } catch (Exception ignored) {
            }
        }

        return activeTokens.containsKey(hashed);
    }

    public void revoke(String refreshToken) {
        if (refreshToken == null) return;

        String hashed = hashToken(refreshToken);
        activeTokens.remove(hashed);

        if (!isMock && jdbcTemplate != null) {
            try {
                String sql = "UPDATE app.refresh_token SET revogado = true WHERE token_hash = ?";
                jdbcTemplate.update(sql, hashed);
            } catch (Exception ignored) {}
        }
    }

    public void revokeAllForUser(Long userId) {
        if (userId == null) return;

        activeTokens.entrySet().removeIf(entry -> entry.getValue().equals(userId));

        if (!isMock && jdbcTemplate != null) {
            try {
                String sql = "UPDATE app.refresh_token SET revogado = true WHERE usuario_id = ?";
                jdbcTemplate.update(sql, userId);
            } catch (Exception ignored) {}
        }
    }

    private String hashToken(String token) {
        if (token == null) return null;
        try {
            java.security.MessageDigest digest = java.security.MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(token.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (java.security.NoSuchAlgorithmException e) {
            throw new IllegalStateException("Algoritmo SHA-256 não disponível", e);
        }
    }
}
