package com.backend.tecsys.auth.service;

import com.backend.tecsys.auth.exception.PasswordMismatchException;
import com.backend.tecsys.auth.model.User;
import com.backend.tecsys.auth.repository.IUserRepository;
import com.backend.tecsys.auth.repository.PasswordResetTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.util.Base64;
import java.util.Optional;

/**
 * Fluxo de recuperação de senha:
 * 1. requestReset(email)  → gera token, envia e-mail com link seguro.
 * 2. validateToken(token) → confirma que o token é válido e não expirado.
 * 3. confirmReset(token, novaSenha, confirmar) → valida, persiste hash e invalida token.
 *
 * Segurança:
 * - Apenas o hash SHA-256 do token é persistido.
 * - Resposta genérica em requestReset (não revela se e-mail existe).
 * - Token de uso único com expiração configurável (padrão: 30 min).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PasswordResetService {

    private final IUserRepository userRepository;
    private final PasswordResetTokenRepository tokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;

    @Value("${password.reset.expiration-minutes:30}")
    private int expiracaoMinutos;

    @Value("${password.reset.frontend-url:http://localhost:3000}")
    private String frontendUrl;

    // ------------------------------------------------------------------ //

    /**
     * Solicita recuperação de senha para o e-mail informado.
     * Retorna silenciosamente mesmo quando o e-mail não existe (evita enumeração).
     */
    public void requestReset(String email) {
        if (email == null || email.isBlank()) return;

        Optional<User> userOpt = userRepository.findByEmail(email.trim().toLowerCase());
        if (userOpt.isEmpty()) {
            // resposta genérica: não revela ausência do e-mail
            log.debug("Solicitação de recuperação para e-mail não cadastrado: {}", email);
            return;
        }

        User user = userOpt.get();
        String rawToken = generateSecureToken();
        String tokenHash = hashToken(rawToken);

        tokenRepository.save(tokenHash, user.getId(), expiracaoMinutos);

        String resetLink = frontendUrl + "/reset-password?token=" + rawToken;
        emailService.sendPasswordResetEmail(user.getEmail(), user.getName(), resetLink, expiracaoMinutos);

        log.info("Link de recuperação de senha enviado para usuário id={}", user.getId());
    }

    /**
     * Verifica se o token é válido e não expirado.
     * Lança {@link InvalidTokenException} quando inválido.
     */
    public void validateToken(String rawToken) {
        String tokenHash = hashToken(rawToken);
        tokenRepository.findUsuarioIdByTokenHash(tokenHash)
                .orElseThrow(() -> new InvalidTokenException("Token inválido ou expirado."));
    }

    /**
     * Confirma a redefinição de senha.
     *
     * @param rawToken          token recebido por e-mail
     * @param novaSenha         nova senha informada
     * @param confirmarNovaSenha confirmação da nova senha
     */
    public void confirmReset(String rawToken, String novaSenha, String confirmarNovaSenha) {
        if (!novaSenha.equals(confirmarNovaSenha)) {
            throw new PasswordMismatchException("As senhas não coincidem.");
        }

        String tokenHash = hashToken(rawToken);
        Long usuarioId = tokenRepository.findUsuarioIdByTokenHash(tokenHash)
                .orElseThrow(() -> new InvalidTokenException("Token inválido ou expirado."));

        User user = userRepository.findById(usuarioId)
                .orElseThrow(() -> new InvalidTokenException("Usuário não encontrado."));

        user.setPassword(passwordEncoder.encode(novaSenha));
        userRepository.update(user);

        tokenRepository.markAsUsed(tokenHash);
        log.info("Senha redefinida com sucesso para usuário id={}", usuarioId);
    }

    // ------------------------------------------------------------------ //

    private String generateSecureToken() {
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String hashToken(String rawToken) {
        try {
            java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(rawToken.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (java.security.NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 indisponível", e);
        }
    }

    // ------------------------------------------------------------------ //

    public static class InvalidTokenException extends RuntimeException {
        public InvalidTokenException(String message) {
            super(message);
        }
    }
}
