package com.backend.tecsys.presentation.controller;

import com.backend.tecsys.application.service.AuthService;
import com.backend.tecsys.application.service.SimulationService;
import com.backend.tecsys.domain.model.GatewayCandidate;
import com.backend.tecsys.domain.model.PropagationModelType;
import com.backend.tecsys.domain.model.ScenarioIndicator;
import com.backend.tecsys.domain.model.User;
import com.backend.tecsys.presentation.dto.SimulationRequest;
import com.backend.tecsys.presentation.dto.SimulationResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/simulations")
@Tag(name = "Simulation", description = "Simulação de cenários de cobertura de ativos.")
public class SimulationController {

    private final SimulationService simulationService;

    public SimulationController(SimulationService simulationService) {
        this.simulationService = simulationService;
    }

    @PostMapping
    @Operation(summary = "Executa a simulação de cenários de cobertura de ativos.")
    public ResponseEntity<SimulationResponse> simulate(
            @Valid @RequestBody SimulationRequest request,
            Authentication authentication) {

        User user = authenticatedUser(authentication);
        PropagationModelType propagationModel = PropagationModelType.fromValue(request.getPropagationModel());

        SimulationService.SimulationCommand command = new SimulationService.SimulationCommand(
                request.getName(),
                request.getRegionName(),
                request.getCoverageTargetPct(),
                request.getMaxGateways(),
                request.getGatewayUnitCost(),
                propagationModel,
                request.toRfParameter());

        SimulationService.SimulationOutcome outcome =
                simulationService.simulate(command, user.getId(), user.getUtilityId());

        return ResponseEntity.ok(toResponse(outcome));
    }

    private User authenticatedUser(Authentication authentication) {
        if (authentication != null && authentication.getPrincipal() instanceof User user) {
            return user;
        }
        throw new AuthService.AuthenticationException("Usuário não autenticado.");
    }

    private SimulationResponse toResponse(SimulationService.SimulationOutcome outcome) {
        ScenarioIndicator indicator = outcome.indicator();

        List<SimulationResponse.SelectedGatewayResponse> selectedGateways = new ArrayList<>();
        for (GatewayCandidate candidate : outcome.selectedGateways()) {
            selectedGateways.add(SimulationResponse.SelectedGatewayResponse.builder()
                    .candidateId(candidate.getId())
                    .latitude(candidate.getCoordinate().latitude())
                    .longitude(candidate.getCoordinate().longitude())
                    .build());
        }

        return SimulationResponse.builder()
                .scenarioId(outcome.scenarioId())
                .status(outcome.status())
                .propagationModel(outcome.propagationModel())
                .rfParameter(outcome.rfParameter())
                .selectedGateways(selectedGateways)
                .totalCoveragePct(indicator.getTotalCoveragePct())
                .coveragePctByAssetType(indicator.getCoveragePctByAssetType())
                .coveredAssetKeys(outcome.coveredAssetKeys())
                .uncoveredAssetKeys(outcome.uncoveredAssetKeys())
                .usedGatewayCount(indicator.getUsedGatewayCount())
                .totalEstimatedCost(indicator.getTotalEstimatedCost() != null
                        ? indicator.getTotalEstimatedCost()
                        : 0.0)
                .processingTimeMs(indicator.getProcessingTimeMs() != null
                        ? indicator.getProcessingTimeMs()
                        : 0)
                .targetReached(indicator.isTargetReached())
                .build();
    }
}
