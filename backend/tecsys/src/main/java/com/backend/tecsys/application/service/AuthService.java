package com.backend.tecsys.application.service;

import com.backend.tecsys.domain.model.User;
import com.backend.tecsys.domain.repository.IUserRepository;
import com.backend.tecsys.infrastructure.security.JwtService;
import com.backend.tecsys.infrastructure.security.RefreshTokenService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final IUserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final RefreshTokenService refreshTokenService;

    public AuthService(
            IUserRepository userRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            RefreshTokenService refreshTokenService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.refreshTokenService = refreshTokenService;
    }

    public AuthResult authenticate(String email, String password) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new AuthenticationException("E-mail ou senha inválidos."));

        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new AuthenticationException("E-mail ou senha inválidos.");
        }

        String accessToken = jwtService.generateToken(
                user.getId(),
                user.getEmail(),
                user.getName(),
                user.getRole()
        );

        String refreshToken = jwtService.generateRefreshToken(user.getId(), user.getEmail());
        refreshTokenService.save(refreshToken, user.getId());

        long expiresIn = jwtService.getExpirationMs() / 1000;

        return new AuthResult(accessToken, refreshToken, expiresIn, user);
    }

    public RefreshResult refresh(String refreshToken) {
        if (refreshToken == null || refreshToken.isBlank()) {
            throw new AuthenticationException("Refresh token não informado.");
        }

        JwtService.TokenValidationStatus status = jwtService.validateToken(refreshToken);
        if (status == JwtService.TokenValidationStatus.EXPIRED) {
            throw new AuthenticationException("Refresh token expirado. Faça login novamente.");
        }
        if (status == JwtService.TokenValidationStatus.INVALID) {
            throw new AuthenticationException("Refresh token inválido.");
        }

        String type = jwtService.extractTokenType(refreshToken);
        if (!"REFRESH".equalsIgnoreCase(type)) {
            throw new AuthenticationException("Token fornecido não é um refresh token válido.");
        }

        if (!refreshTokenService.isValid(refreshToken)) {
            throw new AuthenticationException("Refresh token revogado ou expirado.");
        }

        Long userId = jwtService.extractUserId(refreshToken);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AuthenticationException("Usuário não encontrado."));

        refreshTokenService.revoke(refreshToken);

        String newAccessToken = jwtService.generateToken(
                user.getId(),
                user.getEmail(),
                user.getName(),
                user.getRole()
        );
        String newRefreshToken = jwtService.generateRefreshToken(user.getId(), user.getEmail());
        refreshTokenService.save(newRefreshToken, user.getId());

        long expiresIn = jwtService.getExpirationMs() / 1000;

        return new RefreshResult(newAccessToken, newRefreshToken, expiresIn);
    }

    public void logout(String refreshToken, Long userId) {
        if (refreshToken != null && !refreshToken.isBlank()) {
            refreshTokenService.revoke(refreshToken);
        } else if (userId != null) {
            refreshTokenService.revokeAllForUser(userId);
        }
    }

    public User getUserById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new AuthenticationException("Usuário não encontrado."));
    }

    public record AuthResult(String token, String refreshToken, Long expiresIn, User user) {}

    public record RefreshResult(String accessToken, String refreshToken, Long expiresIn) {}

    public static class AuthenticationException extends RuntimeException {
        public AuthenticationException(String message) {
            super(message);
        }
    }
}
