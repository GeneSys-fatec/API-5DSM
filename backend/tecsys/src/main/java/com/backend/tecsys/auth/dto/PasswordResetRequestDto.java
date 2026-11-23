package com.backend.tecsys.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class PasswordResetRequestDto {

    @NotBlank(message = "O e-mail é obrigatório.")
    @Email(message = "Informe um e-mail válido.")
    private String email;
}
