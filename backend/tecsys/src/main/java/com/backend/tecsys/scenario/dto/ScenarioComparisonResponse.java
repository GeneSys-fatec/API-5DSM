package com.backend.tecsys.scenario.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Resultado da comparação de cenários.")
public class ScenarioComparisonResponse {

    @Schema(description = "Cenários comparados.")
    private List<ScenarioSummaryDto> scenarios;

    @Schema(description = "Indicadores agregados para comparação.")
    private Map<String, Object> comparisonIndicators;
}
