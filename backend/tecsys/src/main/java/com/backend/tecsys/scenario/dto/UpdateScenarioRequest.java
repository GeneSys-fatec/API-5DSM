package com.backend.tecsys.scenario.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Dados para atualizar nome e região de um cenário salvo.")
public class UpdateScenarioRequest {

    @NotBlank(message = "O nome do cenário é obrigatório.")
    @Schema(description = "Novo nome do cenário.", example = "Cenário Centro Atualizado")
    private String name;

    @Schema(description = "Nome da região associada ao cenário.", example = "Centro")
    private String regionName;
}

