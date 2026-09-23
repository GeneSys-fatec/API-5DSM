package com.backend.tecsys.auth.controller;

import com.backend.tecsys.auth.model.User;
import com.backend.tecsys.auth.dto.LoginRequest;
import com.backend.tecsys.auth.dto.LoginResponse;
import com.backend.tecsys.auth.dto.RefreshTokenRequest;
import com.backend.tecsys.auth.dto.TokenRefreshResponse;
import com.backend.tecsys.auth.dto.UserResponse;
import com.backend.tecsys.auth.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/auth")
@Tag(name = "Autenticação", description = "Endpoints de login, renovação de token, logout e sessão")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    @Operation(summary = "Realizar login", description = "Autentica o usuário por e-mail e senha, retornando tokens JWE/JWT de acesso e refresh.")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        AuthService.AuthResult result = authService.authenticate(
                request.getEmail(),
                request.getPassword()
        );

        LoginResponse response = LoginResponse.builder()
                .token(result.token())
                .refreshToken(result.refreshToken())
                .tokenType("Bearer")
                .expiresIn(result.expiresIn())
                .user(UserResponse.fromUser(result.user()))
                .build();

        return ResponseEntity.ok(response);
    }

    @PostMapping("/refresh")
    @Operation(summary = "Renovar access token", description = "Gera um novo access token a partir de um refresh token válido.")
    public ResponseEntity<TokenRefreshResponse> refresh(@Valid @RequestBody RefreshTokenRequest request) {
        AuthService.RefreshResult result = authService.refresh(request.getRefreshToken());

        TokenRefreshResponse response = TokenRefreshResponse.builder()
                .accessToken(result.accessToken())
                .refreshToken(result.refreshToken())
                .tokenType("Bearer")
                .expiresIn(result.expiresIn())
                .build();

        return ResponseEntity.ok(response);
    }

    @PostMapping("/logout")
    @Operation(summary = "Realizar logout", description = "Revoga o refresh token informado e encerra a sessão.")
    public ResponseEntity<Map<String, String>> logout(
            @RequestBody(required = false) RefreshTokenRequest request,
            Authentication authentication) {
        Long userId = null;
        if (authentication != null && authentication.getPrincipal() instanceof User user) {
            userId = user.getId();
        }
        String refreshToken = request != null ? request.getRefreshToken() : null;
        authService.logout(refreshToken, userId);

        return ResponseEntity.ok(Map.of("message", "Logout realizado com sucesso"));
    }

    @GetMapping("/me")
    @Operation(
            summary = "Dados do usuário autenticado",
            description = "Retorna os dados cadastrais do usuário autenticado na sessão atual. Exige Bearer JWT.",
            security = @SecurityRequirement(name = "Bearer Authentication")
    )
    public ResponseEntity<UserResponse> me(Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        return ResponseEntity.ok(UserResponse.fromUser(user));
    }
}

