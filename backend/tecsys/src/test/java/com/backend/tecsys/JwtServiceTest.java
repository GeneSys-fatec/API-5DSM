package com.backend.tecsys;

import com.backend.tecsys.infrastructure.security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class JwtServiceTest {

    private JwtService jwtService;
    private final String secret = "12345678901234567890123456789012-strong-test-secret-key";

    @BeforeEach
    void setUp() {
        jwtService = new JwtService(secret, 3600000L, 604800000L);
    }

    @Test
    void shouldGenerateAndExtractAccessTokenClaims() {
        String token = jwtService.generateToken(1L, "admin@tecsys.com", "Administrador", "ADMIN");

        assertNotNull(token);
        assertEquals(1L, jwtService.extractUserId(token));
        assertEquals("admin@tecsys.com", jwtService.extractEmail(token));
        assertEquals("ADMIN", jwtService.extractRole(token));
        assertEquals("ACCESS", jwtService.extractTokenType(token));
        assertTrue(jwtService.isTokenValid(token));
        assertEquals(JwtService.TokenValidationStatus.VALID, jwtService.validateToken(token));
    }

    @Test
    void shouldGenerateRefreshTokenWithCorrectType() {
        String refreshToken = jwtService.generateRefreshToken(2L, "operador@tecsys.com");

        assertNotNull(refreshToken);
        assertEquals(2L, jwtService.extractUserId(refreshToken));
        assertEquals("operador@tecsys.com", jwtService.extractEmail(refreshToken));
        assertEquals("REFRESH", jwtService.extractTokenType(refreshToken));
        assertTrue(jwtService.isTokenValid(refreshToken));
    }

    @Test
    void shouldDetectExpiredToken() throws InterruptedException {
        JwtService shortLivedJwtService = new JwtService(secret, 1L, 1L);
        String token = shortLivedJwtService.generateToken(1L, "admin@tecsys.com", "Admin", "ADMIN");

        Thread.sleep(10);

        assertEquals(JwtService.TokenValidationStatus.EXPIRED, shortLivedJwtService.validateToken(token));
        assertFalse(shortLivedJwtService.isTokenValid(token));
    }

    @Test
    void shouldDetectInvalidToken() {
        String invalidToken = "invalid.bearer.token";

        assertEquals(JwtService.TokenValidationStatus.INVALID, jwtService.validateToken(invalidToken));
        assertFalse(jwtService.isTokenValid(invalidToken));
    }
}
