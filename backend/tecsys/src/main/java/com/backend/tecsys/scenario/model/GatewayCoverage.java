package com.backend.tecsys.scenario.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GatewayCoverage {
    private GatewayCandidate candidate;
    private double coverageRadiusMeters;

    @Builder.Default
    private Map<String, Double> receivedPowerDbmByAssetKey = new LinkedHashMap<>();

    @Builder.Default
    private Set<String> coveredAssetKeys = new LinkedHashSet<>();

    public boolean covers(String assetKey) {
        return coveredAssetKeys.contains(assetKey);
    }

    public int coveredCount() {
        return coveredAssetKeys.size();
    }
}
