package com.backend.tecsys.presentation.controller;

import com.backend.tecsys.application.service.AuthService;
import com.backend.tecsys.domain.model.User;
import com.backend.tecsys.presentation.dto.LoginRequest;
import com.backend.tecsys.presentation.dto.LoginResponse;
import com.backend.tecsys.presentation.dto.UserResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest request) {
        AuthService.AuthResult result = authService.authenticate(
                request.getEmail(),
                request.getPassword()
        );

        LoginResponse response = LoginResponse.builder()
                .token(result.token())
                .user(UserResponse.fromUser(result.user()))
                .build();

        return ResponseEntity.ok(response);
    }

    @GetMapping("/me")
    public ResponseEntity<UserResponse> me(Authentication authentication) {
        User user = (User) authentication.getPrincipal();
        return ResponseEntity.ok(UserResponse.fromUser(user));
    }
}
