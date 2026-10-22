package com.backend.tecsys.scenario.dto;

import com.backend.tecsys.scenario.model.PropagationModelType;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Resumo de um cenário salvo.")
public class ScenarioSummaryDto {

    @Schema(description = "Identificador do cenário.", example = "1")
    private Long id;

    @Schema(description = "Nome do cenário.", example = "Cenário Centro")
    private String name;

    @Schema(description = "Nome da região associada.", example = "Centro")
    private String regionName;

    @Schema(description = "Meta de cobertura em percentual.", example = "90.0")
    private Double coverageTargetPct;

    @Schema(description = "Quantidade máxima de gateways.", example = "5")
    private Integer maxGateways;

    @Schema(description = "Modelo de propagação utilizado.", example = "OKUMURA_HATA_SUBURBAN")
    private PropagationModelType propagationModel;

    @Schema(description = "Status do cenário.", example = "concluido")
    private String status;

    @Schema(description = "Percentual de cobertura total obtido.", example = "85.5")
    private Double totalCoveragePct;

    @Schema(description = "Quantidade de gateways utilizados.", example = "3")
    private Integer usedGatewayCount;

    @Schema(description = "Custo total estimado.", example = "4500.0")
    private Double totalEstimatedCost;

    @Schema(description = "Data de processamento.", example = "2026-10-13T12:34:56Z")
    private Instant processedAt;
}
