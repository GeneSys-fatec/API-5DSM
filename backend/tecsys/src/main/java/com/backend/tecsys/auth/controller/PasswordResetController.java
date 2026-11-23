package com.backend.tecsys.auth.controller;

import com.backend.tecsys.auth.dto.PasswordResetConfirmDto;
import com.backend.tecsys.auth.dto.PasswordResetRequestDto;
import com.backend.tecsys.auth.service.PasswordResetService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/auth/password-reset")
@Tag(name = "Recuperação de Senha", description = "Endpoints públicos para solicitar e confirmar a redefinição de senha")
@RequiredArgsConstructor
public class PasswordResetController {

    private final PasswordResetService passwordResetService;

    /**
     * POST /auth/password-reset/request
     * Recebe o e-mail, gera o token e envia o link por e-mail.
     * Sempre retorna 200 com resposta genérica (não revela se o e-mail existe).
     */
    @PostMapping("/request")
    @Operation(
        summary = "Solicitar recuperação de senha",
        description = "Envia um link de redefinição ao e-mail informado. Retorna 200 independente de o e-mail existir ou não."
    )
    public ResponseEntity<Map<String, String>> request(
            @Valid @RequestBody PasswordResetRequestDto body) {

        passwordResetService.requestReset(body.getEmail());
        return ResponseEntity.ok(Map.of(
            "message",
            "Se o e-mail estiver cadastrado, você receberá as instruções em breve."
        ));
    }

    /**
     * GET /auth/password-reset/validate?token={token}
     * Verifica se o token ainda é válido e não expirado.
     * Usado pelo front-end ao carregar a tela de redefinição.
     */
    @GetMapping("/validate")
    @Operation(
        summary = "Validar token de recuperação",
        description = "Retorna 200 se o token é válido e 400 se inválido/expirado."
    )
    public ResponseEntity<Map<String, String>> validate(@RequestParam String token) {
        passwordResetService.validateToken(token);
        return ResponseEntity.ok(Map.of("message", "Token válido."));
    }

    /**
     * POST /auth/password-reset/confirm
     * Valida o token, aplica a nova senha e invalida o token.
     */
    @PostMapping("/confirm")
    @Operation(
        summary = "Confirmar redefinição de senha",
        description = "Recebe o token e a nova senha. Retorna 200 em sucesso."
    )
    public ResponseEntity<Map<String, String>> confirm(
            @Valid @RequestBody PasswordResetConfirmDto body) {

        passwordResetService.confirmReset(
            body.getToken(),
            body.getNovaSenha(),
            body.getConfirmarNovaSenha()
        );
        return ResponseEntity.ok(Map.of("message", "Senha redefinida com sucesso."));
    }
}
