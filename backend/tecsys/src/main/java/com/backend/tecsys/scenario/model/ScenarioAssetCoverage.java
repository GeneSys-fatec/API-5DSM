package com.backend.tecsys.scenario.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScenarioAssetCoverage {
    private Long scenarioId;
    private String assetKey;
    private boolean covered;
    private Long selectedGatewayId;
    private Long selectedCandidateId;
}
