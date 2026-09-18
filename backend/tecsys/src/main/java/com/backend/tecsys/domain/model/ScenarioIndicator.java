package com.backend.tecsys.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScenarioIndicator {
    private Long scenarioId;
    private double totalCoveragePct;
    private Map<String, Double> coveragePctByAssetType;
    private int usedGatewayCount;
    private Double totalEstimatedCost;
    private Integer processingTimeMs;
    private boolean targetReached;
    private LocalDateTime calculatedAt;
}
