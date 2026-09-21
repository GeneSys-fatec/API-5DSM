package com.backend.tecsys;

import com.backend.tecsys.scenario.service.GatewaySelectionService;
import com.backend.tecsys.scenario.model.GatewayCandidate;
import com.backend.tecsys.scenario.model.GatewayCoverage;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class GatewaySelectionServiceTest {

    private final GatewaySelectionService service = new GatewaySelectionService();

    @Test
    void shouldStopWhenCoverageTargetIsReached() {
        List<GatewayCoverage> coverages = List.of(
                coverage(1L, "A1", "A2"),
                coverage(2L, "A3", "A4"),
                coverage(3L));

        GatewaySelectionService.SelectionResult result = service.select(coverages, 4, 50.0, 3);

        assertEquals(1, result.selectedCoverages().size());
        assertEquals(2, result.coveredAssetKeys().size());
        assertTrue(result.targetReached());
    }

    @Test
    void shouldStopAtMaxGateways() {
        List<GatewayCoverage> coverages = List.of(
                coverage(1L, "A1"),
                coverage(2L, "A2"),
                coverage(3L, "A3"));

        GatewaySelectionService.SelectionResult result = service.select(coverages, 4, 100.0, 2);

        assertEquals(2, result.selectedCoverages().size());
        assertEquals(2, result.coveredAssetKeys().size());
        assertFalse(result.targetReached());
    }

    @Test
    void shouldCompleteWhenTargetIsNotReachedAtMaxGateways() {
        List<GatewayCoverage> coverages = List.of(
                coverage(1L, "A1"),
                coverage(2L, "A2"));

        GatewaySelectionService.SelectionResult result = service.select(coverages, 5, 100.0, 2);

        assertEquals(2, result.selectedCoverages().size());
        assertFalse(result.targetReached());
    }

    @Test
    void shouldHandleScenarioWithFewCandidates() {
        List<GatewayCoverage> coverages = List.of(coverage(1L, "A1"));

        GatewaySelectionService.SelectionResult result = service.select(coverages, 3, 100.0, 5);

        assertEquals(1, result.selectedCoverages().size());
        assertFalse(result.targetReached());
    }

    @Test
    void shouldSelectSingleGatewayThatCoversMultipleAssets() {
        List<GatewayCoverage> coverages = List.of(
                coverage(1L, "A1", "A2", "A3"),
                coverage(2L, "A1"));

        GatewaySelectionService.SelectionResult result = service.select(coverages, 3, 100.0, 5);

        assertEquals(1, result.selectedCoverages().size());
        assertEquals(3, result.coveredAssetKeys().size());
        assertTrue(result.targetReached());
        assertEquals(1L, result.selectedCoverages().get(0).getCandidate().getId());
    }

    private GatewayCoverage coverage(Long candidateId, String... assetKeys) {
        GatewayCandidate candidate = GatewayCandidate.builder().id(candidateId).build();
        return GatewayCoverage.builder()
                .candidate(candidate)
                .coveredAssetKeys(new LinkedHashSet<>(Arrays.asList(assetKeys)))
                .build();
    }
}
