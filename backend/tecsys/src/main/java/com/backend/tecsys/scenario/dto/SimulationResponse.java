package com.backend.tecsys.scenario.dto;

import com.backend.tecsys.scenario.model.PropagationModelType;
import com.backend.tecsys.radio.model.RfParameter;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
@Schema(description = "Resultado da simulação de cobertura.")
public class SimulationResponse {

    @Schema(description = "Identificador do cenário persistido.", example = "1")
    private Long scenarioId;

    @Schema(description = "Nome informado para o cenário.", example = "Cenário urbano")
    private String scenarioName;

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

    @Schema(description = "RSSI médio dos ativos conectados, em dBm.", example = "-86.4", nullable = true)
    private Double averageRssiDbm;

    @Schema(description = "Custo unitário efetivamente aplicado a cada gateway.", example = "1500")
    private Double gatewayUnitCost;

    @Schema(description = "Meta de cobertura informada.")
    private double coverageTargetPct;

    @Schema(description = "Limite de gateways informado.")
    private int maxGateways;

    @Schema(description = "Ativos e suas posições geográficas no resultado.")
    private List<AssetLocationResponse> assets;

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    @Schema(description = "Ativo avaliado pela simulação.")
    public static class AssetLocationResponse {
        private String assetKey;
        private String type;
        private double latitude;
        private double longitude;
        private boolean covered;
    }

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
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

        @Schema(description = "Geometria GeoJSON da cobertura efetiva, quando calculada com relevo.")
        private String coverageGeometryGeoJson;

        @Schema(description = "Ativos bloqueados por obstrução de relevo.")
        private List<String> shadowedAssetKeys;
    }
}
