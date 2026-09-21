package com.backend.tecsys.auth.controller;

import com.backend.tecsys.auth.model.User;
import com.backend.tecsys.auth.dto.LoginRequest;
import com.backend.tecsys.auth.dto.LoginResponse;
import com.backend.tecsys.auth.dto.RefreshTokenRequest;
import com.backend.tecsys.auth.dto.TokenRefreshResponse;
import com.backend.tecsys.auth.dto.UserResponse;
import com.backend.tecsys.auth.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
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
    public ResponseEntity<UserResponse> me(Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        return ResponseEntity.ok(UserResponse.fromUser(user));
    }
}
