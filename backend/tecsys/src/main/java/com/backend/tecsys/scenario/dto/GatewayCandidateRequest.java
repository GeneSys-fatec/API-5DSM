package com.backend.tecsys.scenario.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GatewayCandidateRequest {

    @NotNull(message = "O identificador do candidato a gateway é obrigatório.")
    private Long id;

    private String source;

    private String assetKey;

    @NotNull(message = "A latitude do candidato a gateway é obrigatória.")
    private Double latitude;

    @NotNull(message = "A longitude do candidato a gateway é obrigatória.")
    private Double longitude;

    private Double estimatedCost;
}