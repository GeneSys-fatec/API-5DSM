package com.backend.tecsys.infrastructure.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Date;
import java.util.UUID;

@Service
public class JwtService {

    public enum TokenValidationStatus {
        VALID,
        EXPIRED,
        INVALID
    }

    private final SecretKey key;
    private final long expirationMs;
    private final long refreshExpirationMs;

    public JwtService(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.expiration-ms}") long expirationMs,
            @Value("${jwt.refresh-expiration-ms:604800000}") long refreshExpirationMs) {
        this.key = deriveAesKey(secret);
        this.expirationMs = expirationMs;
        this.refreshExpirationMs = refreshExpirationMs;
    }

    private static final String DEFAULT_DEV_SECRET = "tecsys-rf-planning-secret-key-change-in-production-2024";

    private SecretKey deriveAesKey(String secret) {
        String effectiveSecret = (secret != null && !secret.isBlank()) ? secret : DEFAULT_DEV_SECRET;
        try {
            MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
            byte[] keyBytes = sha256.digest(effectiveSecret.getBytes(StandardCharsets.UTF_8));
            return new SecretKeySpec(keyBytes, "AES");
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("Algoritmo SHA-256 não disponível no ambiente Java.", e);
        }
    }

    public String generateToken(Long userId, String email, String name, String role) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + expirationMs);

        return Jwts.builder()
                .id(UUID.randomUUID().toString())
                .subject(userId.toString())
                .claim("email", email)
                .claim("name", name)
                .claim("role", role != null ? role : "USER")
                .claim("type", "ACCESS")
                .issuedAt(now)
                .expiration(expiry)
                .encryptWith(key, Jwts.ENC.A256GCM)
                .compact();
    }

    public String generateToken(Long userId, String email) {
        return generateToken(userId, email, null, "USER");
    }

    public String generateRefreshToken(Long userId, String email) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + refreshExpirationMs);

        return Jwts.builder()
                .id(UUID.randomUUID().toString())
                .subject(userId.toString())
                .claim("email", email)
                .claim("type", "REFRESH")
                .issuedAt(now)
                .expiration(expiry)
                .encryptWith(key, Jwts.ENC.A256GCM)
                .compact();
    }

    public Long extractUserId(String token) {
        Claims claims = parseToken(token);
        return Long.parseLong(claims.getSubject());
    }

    public String extractEmail(String token) {
        Claims claims = parseToken(token);
        return claims.get("email", String.class);
    }

    public String extractRole(String token) {
        Claims claims = parseToken(token);
        return claims.get("role", String.class);
    }

    public String extractTokenType(String token) {
        Claims claims = parseToken(token);
        return claims.get("type", String.class);
    }

    public TokenValidationStatus validateToken(String token) {
        try {
            parseToken(token);
            return TokenValidationStatus.VALID;
        } catch (ExpiredJwtException e) {
            return TokenValidationStatus.EXPIRED;
        } catch (JwtException | IllegalArgumentException e) {
            return TokenValidationStatus.INVALID;
        }
    }

    public boolean isTokenValid(String token) {
        return validateToken(token) == TokenValidationStatus.VALID;
    }

    public long getExpirationMs() {
        return expirationMs;
    }

    public long getRefreshExpirationMs() {
        return refreshExpirationMs;
    }

    private Claims parseToken(String token) {
        return Jwts.parser()
                .decryptWith(key)
                .build()
                .parseEncryptedClaims(token)
                .getPayload();
    }
}
