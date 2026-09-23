package com.backend.tecsys.auth.dto;

import com.backend.tecsys.auth.model.User;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Dados públicos de retorno do usuário")
public class UserResponse {

    @Schema(description = "Identificador único do usuário", example = "1")
    private Long id;

    @Schema(description = "Nome do usuário", example = "João da Silva")
    private String name;

    @Schema(description = "E-mail do usuário", example = "joao.silva@tecsys.com")
    private String email;

    @Schema(description = "Papel/permissão do usuário no sistema", example = "ENGENHEIRO")
    private String role;

    @Schema(description = "Data e hora de criação", example = "2026-09-21T10:00:00")
    private LocalDateTime createdAt;

    @Schema(description = "Data e hora da última atualização", example = "2026-09-21T10:00:00")
    private LocalDateTime updatedAt;

    @JsonProperty("nome")
    public String getNome() {
        return name;
    }

    @JsonProperty("papel")
    public String getPapel() {
        return role;
    }

    @JsonProperty("criadoEm")
    public LocalDateTime getCriadoEm() {
        return createdAt;
    }

    @JsonProperty("atualizadoEm")
    public LocalDateTime getAtualizadoEm() {
        return updatedAt;
    }

    public static UserResponse fromUser(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .role(user.getRole())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .build();
    }
}
