package com.backend.tecsys.scenario.service;

import com.backend.tecsys.scenario.model.GatewayCoverage;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class SimulationServiceAverageRssiTest {
    @Test
    void averagesTheStrongestSelectedGatewaySignalPerConnectedAsset() {
        List<GatewayCoverage> coverages = List.of(
                coverage(Map.of("asset-1", -85.0, "asset-2", -90.0)),
                coverage(Map.of("asset-1", -70.0)));

        assertEquals(-80.0, SimulationService.calculateAverageRssi(coverages), 1e-9);
    }

    @Test
    void returnsNullWhenNoAssetsAreCovered() {
        assertNull(SimulationService.calculateAverageRssi(List.of(coverage(Map.of()))));
    }

    private GatewayCoverage coverage(Map<String, Double> receivedPowerByAsset) {
        return GatewayCoverage.builder()
                .receivedPowerDbmByAssetKey(receivedPowerByAsset)
                .build();
    }
}
