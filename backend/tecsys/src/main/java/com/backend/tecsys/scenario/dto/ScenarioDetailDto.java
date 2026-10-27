package com.backend.tecsys.scenario.dto;

import com.backend.tecsys.radio.model.RfParameter;
import com.backend.tecsys.scenario.model.PropagationModelType;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Detalhes completos de um cenário salvo.")
public class ScenarioDetailDto {

    @Schema(description = "Identificador do cenário.", example = "1")
    private Long id;

    @Schema(description = "Nome do cenário.", example = "Cenário Centro")
    private String name;

    @Schema(description = "Nome da região associada.", example = "Centro")
    private String regionName;

    @Schema(description = "Área delimitada em WKT.", example = "POLYGON((...))")
    private String areaWkt;

    @Schema(description = "Meta de cobertura em percentual.", example = "90.0")
    private Double coverageTargetPct;

    @Schema(description = "Quantidade máxima de gateways.", example = "5")
    private Integer maxGateways;

    @Schema(description = "Custo unitário do gateway.", example = "1500.0")
    private Double gatewayUnitCost;

    @Schema(description = "Modelo de propagação utilizado.", example = "OKUMURA_HATA_SUBURBAN")
    private PropagationModelType propagationModel;

    @Schema(description = "Parâmetros RF utilizados.")
    private RfParameter rfParameter;

    @Schema(description = "Status do cenário.", example = "concluido")
    private String status;

    @Schema(description = "Tempo de processamento em ms.", example = "42")
    private Integer processingTimeMs;

    @Schema(description = "Data de processamento.", example = "2026-10-13T12:34:56Z")
    private Instant processedAt;

    @Schema(description = "Gateways selecionados.")
    private List<SelectedGatewayDto> selectedGateways;

    @Schema(description = "Indicadores do cenário.")
    private ScenarioIndicatorDto indicator;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @Schema(description = "Gateway selecionado no cenário.")
    public static class SelectedGatewayDto {
        @Schema(description = "Identificador do candidato a gateway.", example = "10")
        private Long candidateId;
        @Schema(description = "Latitude.", example = "-22.5")
        private Double latitude;
        @Schema(description = "Longitude.", example = "-47.2")
        private Double longitude;
        @Schema(description = "Raio de cobertura em metros.", example = "1850.5")
        private Double coverageRadiusMeters;
        @Schema(description = "Ajustado manualmente?", example = "false")
        private Boolean manuallyAdjusted;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @Schema(description = "Indicadores do cenário.")
    public static class ScenarioIndicatorDto {
        @Schema(description = "Percentual de cobertura total.", example = "85.5")
        private Double totalCoveragePct;
        @Schema(description = "Cobertura por tipo de ativo.")
        private Map<String, Double> coveragePctByAssetType;
        @Schema(description = "Quantidade de gateways utilizados.", example = "3")
        private Integer usedGatewayCount;
        @Schema(description = "Custo total estimado.", example = "4500.0")
        private Double totalEstimatedCost;
        @Schema(description = "Meta atingida?", example = "true")
        private Boolean targetReached;
    }
}
