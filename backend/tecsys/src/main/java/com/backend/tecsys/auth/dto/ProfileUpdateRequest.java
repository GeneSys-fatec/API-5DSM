package com.backend.tecsys.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Dados personalizáveis do perfil do usuário autenticado")
public class ProfileUpdateRequest {

    @NotBlank(message = "O nome de exibição é obrigatório")
    @Size(max = 120, message = "O nome de exibição deve ter no máximo 120 caracteres")
    @Schema(description = "Nome exibido no sistema", example = "João da Silva")
    private String nome;

    @Size(max = 1000, message = "A URL do avatar deve ter no máximo 1000 caracteres")
    @Pattern(regexp = "^$|^/.*|^https?://.*", message = "O avatar deve ser uma URL relativa ou absoluta HTTP/HTTPS")
    @Schema(description = "URL relativa ou absoluta HTTP/HTTPS da foto do perfil", example = "/users/1/avatar")
    private String avatarUrl;
}
