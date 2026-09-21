package com.backend.tecsys;

import com.backend.tecsys.scenario.service.ScenarioIndicatorCalculator;
import com.backend.tecsys.scenario.model.Asset;
import com.backend.tecsys.scenario.model.ScenarioIndicator;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ScenarioIndicatorCalculatorTest {

    private final ScenarioIndicatorCalculator calculator = new ScenarioIndicatorCalculator();

    @Test
    void shouldCalculateScenarioIndicators() {
        List<Asset> assets = List.of(
                Asset.builder().assetKey("A1").assetType("POSTE").build(),
                Asset.builder().assetKey("A2").assetType("POSTE").build(),
                Asset.builder().assetKey("A3").assetType("UCBT").build(),
                Asset.builder().assetKey("A4").assetType("UCBT").build());

        ScenarioIndicator indicator = calculator.calculate(
                assets,
                Set.of("A1", "A3"),
                2,
                3000.0,
                15,
                false);

        assertEquals(50.0, indicator.getTotalCoveragePct(), 0.001);
        assertEquals(50.0, indicator.getCoveragePctByAssetType().get("POSTE"), 0.001);
        assertEquals(50.0, indicator.getCoveragePctByAssetType().get("UCBT"), 0.001);
        assertEquals(2, indicator.getUsedGatewayCount());
        assertEquals(3000.0, indicator.getTotalEstimatedCost(), 0.001);
        assertFalse(indicator.isTargetReached());
    }

    @Test
    void shouldMarkTargetAsReachedWhenCoverageIsComplete() {
        List<Asset> assets = List.of(
                Asset.builder().assetKey("A1").assetType("POSTE").build(),
                Asset.builder().assetKey("A2").assetType("POSTE").build());

        ScenarioIndicator indicator = calculator.calculate(
                assets,
                Set.of("A1", "A2"),
                1,
                1500.0,
                5,
                true);

        assertEquals(100.0, indicator.getTotalCoveragePct(), 0.001);
        assertTrue(indicator.isTargetReached());
    }
}
