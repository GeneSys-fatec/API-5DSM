package com.backend.tecsys.auth.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Dados para alteração segura de senha do usuário autenticado")
public class ChangePasswordRequest {

    @NotBlank(message = "A senha atual é obrigatória")
    @ToString.Exclude
    @JsonAlias({"currentPassword", "senhaAntiga", "oldPassword"})
    @Schema(description = "Senha atual do usuário", example = "SenhaAntiga@123")
    private String senhaAtual;

    @NotBlank(message = "A nova senha é obrigatória")
    @Size(min = 6, message = "A nova senha deve ter pelo menos 6 caracteres")
    @ToString.Exclude
    @JsonAlias({"newPassword", "senha"})
    @Schema(description = "Nova senha do usuário (mínimo 6 caracteres)", example = "NovaSenha@456")
    private String novaSenha;

    @NotBlank(message = "A confirmação da nova senha é obrigatória")
    @ToString.Exclude
    @JsonAlias({"confirmNewPassword", "confirmarSenha", "confirmPassword"})
    @Schema(description = "Confirmação da nova senha", example = "NovaSenha@456")
    private String confirmarNovaSenha;
}
