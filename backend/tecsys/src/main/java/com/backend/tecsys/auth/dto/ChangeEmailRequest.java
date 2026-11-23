package com.backend.tecsys.auth.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Dados para alteração segura do e-mail do usuário autenticado")
public class ChangeEmailRequest {

    @NotBlank(message = "O novo e-mail é obrigatório")
    @Email(message = "Formato de e-mail inválido")
    @JsonAlias({"newEmail", "email"})
    @Schema(description = "Novo e-mail do usuário", example = "novo.email@tecsys.com")
    private String novoEmail;

    @NotBlank(message = "A senha atual é obrigatória para confirmação")
    @ToString.Exclude
    @JsonAlias({"password", "senhaAtual", "currentPassword"})
    @Schema(description = "Senha atual do usuário para confirmação", example = "Senha@123")
    private String senha;
}
