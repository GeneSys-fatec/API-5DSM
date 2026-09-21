package com.backend.tecsys.scenario.dto;

import com.backend.tecsys.scenario.model.PropagationModelType;
import com.backend.tecsys.radio.model.RfParameter;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.util.List;
import java.util.Map;

@Data
@Builder
@AllArgsConstructor
@Schema(description = "Resultado da simulação de cobertura.")
public class SimulationResponse {

    @Schema(description = "Identificador do cenário persistido.", example = "1")
    private Long scenarioId;

    @Schema(description = "Status da execução.", example = "concluido")
    private String status;

    @Schema(description = "Modelo de propagação utilizado.", example = "OKUMURA_HATA_SUBURBAN")
    private PropagationModelType propagationModel;

    @Schema(description = "Parâmetros RF efetivamente utilizados.")
    private RfParameter rfParameter;

    @Schema(description = "Gateways selecionados pelo algoritmo.")
    private List<SelectedGatewayResponse> selectedGateways;

    @Schema(description = "Percentual de cobertura total.", example = "85.0")
    private double totalCoveragePct;

    @Schema(description = "Percentual de cobertura por tipo de ativo.")
    private Map<String, Double> coveragePctByAssetType;

    @Schema(description = "Chaves dos ativos cobertos.")
    private List<String> coveredAssetKeys;

    @Schema(description = "Chaves dos ativos não cobertos.")
    private List<String> uncoveredAssetKeys;

    @Schema(description = "Quantidade de gateways utilizados.", example = "3")
    private int usedGatewayCount;

    @Schema(description = "Custo total estimado.", example = "4500.0")
    private double totalEstimatedCost;

    @Schema(description = "Tempo de processamento em milissegundos.", example = "42")
    private int processingTimeMs;

    @Schema(description = "Indica se a meta de cobertura foi atingida.", example = "true")
    private boolean targetReached;

    @Data
    @Builder
    @AllArgsConstructor
    @Schema(description = "Gateway selecionado na simulação.")
    public static class SelectedGatewayResponse {
        @Schema(description = "Identificador do candidato a gateway.", example = "1")
        private Long candidateId;

        @Schema(description = "Latitude do gateway.", example = "-22.0")
        private double latitude;

        @Schema(description = "Longitude do gateway.", example = "-47.0")
        private double longitude;

        @Schema(description = "Raio estimado de cobertura em metros.", example = "1850.5")
        private double coverageRadiusMeters;
    }
}
