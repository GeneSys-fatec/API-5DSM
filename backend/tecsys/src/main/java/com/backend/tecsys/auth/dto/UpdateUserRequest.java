package com.backend.tecsys.auth.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
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
@Schema(description = "Dados para atualização cadastral de um usuário")
public class UpdateUserRequest {

    @Schema(description = "Novo nome completo", example = "João da Silva Santos")
    @JsonAlias({"name"})
    private String nome;

    @Schema(description = "Novo e-mail único", example = "joao.novo@tecsys.com")
    @Email(message = "Formato de e-mail inválido")
    @JsonAlias({"email"})
    private String email;

    @Schema(description = "Nova senha (mínimo 6 caracteres). Se informada, exige confirmação.", example = "NovaSenha@123")
    @Size(min = 6, message = "A nova senha deve ter pelo menos 6 caracteres")
    @ToString.Exclude
    @JsonAlias({"password", "novaSenha"})
    private String senha;

    @Schema(description = "Confirmação da nova senha", example = "NovaSenha@123")
    @ToString.Exclude
    @JsonAlias({"confirmPassword", "confirmarNovaSenha"})
    private String confirmarSenha;
}
