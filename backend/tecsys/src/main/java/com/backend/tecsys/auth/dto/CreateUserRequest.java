package com.backend.tecsys.auth.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
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
@Schema(description = "Dados para criação/cadastro de um novo usuário")
public class CreateUserRequest {

    @Schema(description = "Nome completo do usuário", example = "João da Silva", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank(message = "O nome é obrigatório")
    @JsonAlias({"name"})
    private String nome;

    @Schema(description = "E-mail válido e único do usuário", example = "joao.silva@tecsys.com", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank(message = "O e-mail é obrigatório")
    @Email(message = "Formato de e-mail inválido")
    private String email;

    @Schema(description = "Senha de acesso (mínimo 6 caracteres)", example = "Senha@123", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank(message = "A senha é obrigatória")
    @Size(min = 6, message = "A senha deve ter pelo menos 6 caracteres")
    @ToString.Exclude
    @JsonAlias({"password"})
    private String senha;

    @Schema(description = "Confirmação da senha (deve ser idêntica à senha)", example = "Senha@123", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank(message = "A confirmação de senha é obrigatória")
    @ToString.Exclude
    @JsonAlias({"confirmPassword"})
    private String confirmarSenha;
}
