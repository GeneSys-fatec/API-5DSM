package com.backend.tecsys.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class PasswordResetConfirmDto {

    @NotBlank(message = "O token é obrigatório.")
    private String token;

    @NotBlank(message = "A nova senha é obrigatória.")
    @Size(min = 8, message = "A senha deve ter no mínimo 8 caracteres.")
    @Pattern(
        regexp = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)(?=.*[^A-Za-z0-9]).+$",
        message = "A senha deve conter ao menos uma letra maiúscula, uma minúscula, um número e um caractere especial."
    )
    private String novaSenha;

    @NotBlank(message = "A confirmação da senha é obrigatória.")
    private String confirmarNovaSenha;
}
