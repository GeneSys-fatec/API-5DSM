package com.backend.tecsys.scenario.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Requisição para comparação de cenários.")
public class ScenarioComparisonRequest {

    @NotEmpty(message = "É necessário informar ao menos dois cenários para comparação.")
    @Schema(description = "Lista de identificadores dos cenários a comparar.", example = "[1, 2, 3]")
    private List<Long> scenarioIds;
}
