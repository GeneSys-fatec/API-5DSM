package com.backend.tecsys.infrastructure.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

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
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expirationMs = expirationMs;
        this.refreshExpirationMs = refreshExpirationMs;
    }

    public String generateToken(Long userId, String email, String name, String role) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + expirationMs);

        return Jwts.builder()
                .id(java.util.UUID.randomUUID().toString())
                .subject(userId.toString())
                .claim("email", email)
                .claim("name", name)
                .claim("role", role != null ? role : "USER")
                .claim("type", "ACCESS")
                .issuedAt(now)
                .expiration(expiry)
                .signWith(key)
                .compact();
    }

    public String generateToken(Long userId, String email) {
        return generateToken(userId, email, null, "USER");
    }

    public String generateRefreshToken(Long userId, String email) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + refreshExpirationMs);

        return Jwts.builder()
                .id(java.util.UUID.randomUUID().toString())
                .subject(userId.toString())
                .claim("email", email)
                .claim("type", "REFRESH")
                .issuedAt(now)
                .expiration(expiry)
                .signWith(key)
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
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
