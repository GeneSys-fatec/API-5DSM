package com.backend.tecsys;

import com.backend.tecsys.bdgd.service.BdgdAssetService;
import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.radio.model.RfParameter;
import com.backend.tecsys.radio.service.PropagationModelRegistry;
import com.backend.tecsys.radio.service.RadioCoverageCalculator;
import com.backend.tecsys.scenario.exception.PointOutOfBoundsException;
import com.backend.tecsys.scenario.model.GatewayCandidate;
import com.backend.tecsys.scenario.model.PropagationModelType;
import com.backend.tecsys.scenario.repository.GatewayCandidateProvider;
import com.backend.tecsys.scenario.repository.IAssetRepository;
import com.backend.tecsys.scenario.repository.IScenarioRepository;
import com.backend.tecsys.scenario.service.CostCalculator;
import com.backend.tecsys.scenario.service.GatewaySelectionService;
import com.backend.tecsys.scenario.service.ScenarioIndicatorCalculator;
import com.backend.tecsys.scenario.service.SimulationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class SimulationServiceBoundaryTest {

    private final IAssetRepository assetRepository = mock(IAssetRepository.class);
    private final BdgdAssetService bdgdAssetService = mock(BdgdAssetService.class);
    private final PropagationModelRegistry propagationModelRegistry = mock(PropagationModelRegistry.class);
    private final RadioCoverageCalculator radioCoverageCalculator = mock(RadioCoverageCalculator.class);
    private final GatewaySelectionService gatewaySelectionService = new GatewaySelectionService();
    private final ScenarioIndicatorCalculator scenarioIndicatorCalculator = mock(ScenarioIndicatorCalculator.class);
    private final CostCalculator costCalculator = mock(CostCalculator.class);
    private final IScenarioRepository scenarioRepository = mock(IScenarioRepository.class);

    private SimulationService service;

    @BeforeEach
    void setUp() {
        service = new SimulationService(
                assetRepository,
                bdgdAssetService,
                propagationModelRegistry,
                radioCoverageCalculator,
                gatewaySelectionService,
                scenarioIndicatorCalculator,
                costCalculator,
                scenarioRepository);
    }

    @Test
    void shouldRejectSimulationWhenCenterIsOutsideBdgdBounds() {
        UUID importId = UUID.randomUUID();
        when(bdgdAssetService.checkPointWithinImportBounds(any(UUID.class), anyDouble(), anyDouble()))
                .thenReturn(new BdgdAssetService.BoundaryCheck(samplePolygon(), false));

        SimulationService.SimulationCommand command = commandWithSearchArea(importId);

        assertThrows(PointOutOfBoundsException.class,
                () -> service.simulate(command, 1L, 1L));
    }

    @Test
    void shouldSkipBoundaryValidationWhenNoSearchAreaProvided() {
        UUID importId = UUID.randomUUID();
        SimulationService.SimulationCommand command = commandWithoutSearchArea(importId);

        try {
            service.simulate(command, 1L, 1L);
        } catch (Exception ignored) {
        }

        org.mockito.Mockito.verifyNoInteractions(bdgdAssetService);
    }

    private SimulationService.SimulationCommand commandWithSearchArea(UUID importId) {
        return new SimulationService.SimulationCommand(
                importId,
                "Cenario Teste",
                "Regiao Teste",
                90.0,
                5,
                1500.0,
                PropagationModelType.OKUMURA_HATA_SUBURBAN,
                RfParameter.defaults(),
                List.of(GatewayCandidate.builder()
                        .id(1L)
                        .assetKey("CANDIDATE-1")
                        .coordinate(new RfCoordinate(-11.0, -37.0))
                        .estimatedCost(1500.0)
                        .build()),
                -11.0,
                -37.0,
                3500.0);
    }

    private SimulationService.SimulationCommand commandWithoutSearchArea(UUID importId) {
        return new SimulationService.SimulationCommand(
                importId,
                "Cenario Teste",
                "Regiao Teste",
                90.0,
                5,
                1500.0,
                PropagationModelType.OKUMURA_HATA_SUBURBAN,
                RfParameter.defaults(),
                List.of(GatewayCandidate.builder()
                        .id(1L)
                        .assetKey("CANDIDATE-1")
                        .coordinate(new RfCoordinate(-11.0, -37.0))
                        .estimatedCost(1500.0)
                        .build()),
                null,
                null,
                null);
    }

    private Object samplePolygon() {
        return java.util.Map.of("type", "Polygon", "coordinates", List.of());
    }
}