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
    void shouldBeEncryptedJweWithFivePartsAndNoPlaintextClaims() {
        String email = "admin@tecsys.com";
        String token = jwtService.generateToken(1L, email, "Administrador", "ADMIN");

        // Standard JWE compact serialization has 5 parts: header.encryptedKey.iv.ciphertext.tag
        String[] parts = token.split("\\.");
        assertEquals(5, parts.length, "O token JWE deve possuir 5 partes separadas por ponto.");

        // In standard JWS (signed), parts[1] is base64(claims). In JWE, the payload is in ciphertext (parts[3])
        // and cannot be decoded into the raw email string.
        assertFalse(token.contains(email), "O e-mail não pode aparecer em texto plano dentro do token.");
        for (String part : parts) {
            String decoded = new String(java.util.Base64.getUrlDecoder().decode(part), java.nio.charset.StandardCharsets.UTF_8);
            assertFalse(decoded.contains(email), "Nenhuma parte decodificada em Base64 pode conter o e-mail em texto puro.");
        }
    }

    @Test
    void shouldRejectTokenWhenDecryptedWithWrongKey() {
        String token = jwtService.generateToken(1L, "admin@tecsys.com", "Admin", "ADMIN");
        JwtService differentKeyService = new JwtService("different-secret-key-that-does-not-match-at-all-32chars", 3600000L, 604800000L);

        assertEquals(JwtService.TokenValidationStatus.INVALID, differentKeyService.validateToken(token));
        assertFalse(differentKeyService.isTokenValid(token));
    }

    @Test
    void shouldUseFallbackWhenSecretIsBlank() {
        JwtService fallbackService = new JwtService("", 3600000L, 604800000L);
        String token = fallbackService.generateToken(1L, "admin@tecsys.com", "Admin", "ADMIN");
        assertNotNull(token);
        assertTrue(fallbackService.isTokenValid(token));
        assertEquals("admin@tecsys.com", fallbackService.extractEmail(token));
    }
}
