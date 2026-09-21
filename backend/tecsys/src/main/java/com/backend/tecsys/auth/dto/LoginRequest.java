package com.backend.tecsys.auth.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Requisição de login")
public class LoginRequest {
    @Schema(description = "E-mail do usuário", example = "tiago.teste@tecsys.com")
    @NotBlank(message = "O e-mail é obrigatório.")
    @Email(message = "Formato de e-mail inválido.")
    private String email;

    @Schema(description = "Senha de acesso (aceita 'password' ou 'senha')", example = "Senha@123")
    @JsonAlias({"senha", "password"})
    @NotBlank(message = "A senha é obrigatória.")
    private String password;
}

