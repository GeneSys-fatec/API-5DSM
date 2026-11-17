package com.backend.tecsys.scenario.controller;

import com.backend.tecsys.auth.model.User;
import com.backend.tecsys.scenario.dto.*;
import com.backend.tecsys.scenario.dto.SimulationRequest;
import com.backend.tecsys.scenario.model.PropagationModelType;
import com.backend.tecsys.scenario.model.Scenario;
import com.backend.tecsys.scenario.model.ScenarioAssetLocation;
import com.backend.tecsys.scenario.model.ScenarioIndicator;
import com.backend.tecsys.scenario.model.ScenarioSelectedGateway;
import com.backend.tecsys.scenario.service.ScenarioService;
import com.backend.tecsys.scenario.service.SimulationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/scenarios")
@Tag(name = "Cenários", description = "Operações de gerenciamento de cenários salvos por região.")
public class ScenarioController {

    private final ScenarioService scenarioService;
    private final SimulationService simulationService;

    public ScenarioController(ScenarioService scenarioService, SimulationService simulationService) {
        this.scenarioService = scenarioService;
        this.simulationService = simulationService;
    }

    private User authenticatedUser(Authentication authentication) {
        if (authentication != null && authentication.getPrincipal() instanceof User user) {
            return user;
        }
        throw new RuntimeException("Usuário não autenticado.");
    }

    @PostMapping
    @Operation(summary = "Salvar cenário simulado", description = "Executa simulação e persiste cenário com área delimitada, parâmetros de otimização, RF e resultado.", security = @SecurityRequirement(name = "Bearer Authentication"))
    public ResponseEntity<ScenarioSummaryDto> saveScenario(
            Authentication authentication,
            @Valid @RequestBody SimulationRequest request) {

        User user = authenticatedUser(authentication);
        SimulationService.SimulationCommand command = new SimulationService.SimulationCommand(
                request.getImportId(),
                request.getName(),
                request.getRegionName(),
                request.getCoverageTargetPct(),
                request.getMaxGateways(),
                request.getGatewayUnitCost(),
                PropagationModelType.fromValue(request.getPropagationModel()),
                request.toRfParameter(),
                request.toGatewayCandidates(user.getUtilityId()),
                request.getSearchCenterLatitude(),
                request.getSearchCenterLongitude(),
                request.getSearchRadiusMeters(),
                request.getSearchPolygonPoints()
        );

        SimulationService.SimulationOutcome outcome = simulationService.simulate(command, user.getId(), user.getUtilityId());

        ScenarioSummaryDto dto = ScenarioSummaryDto.builder()
                .id(outcome.scenarioId())
                .name(request.getName())
                .regionName(request.getRegionName())
                .coverageTargetPct(request.getCoverageTargetPct())
                .maxGateways(request.getMaxGateways())
                .propagationModel(outcome.propagationModel())
                .status(outcome.status())
                .totalCoveragePct(outcome.indicator().getTotalCoveragePct())
                .usedGatewayCount(outcome.indicator().getUsedGatewayCount())
                .totalEstimatedCost(outcome.indicator().getTotalEstimatedCost())
                .build();

        return ResponseEntity.ok(dto);
    }

    @GetMapping
    @Operation(summary = "Listar cenários salvos", description = "Lista cenários do usuário autenticado, opcionalmente filtrados por região.", security = @SecurityRequirement(name = "Bearer Authentication"))
    public ResponseEntity<List<ScenarioSummaryDto>> listScenarios(
            Authentication authentication,
            @Parameter(description = "Nome da região para filtrar.") @RequestParam(required = false) String regionName) {

        User user = authenticatedUser(authentication);
        List<Scenario> scenarios = scenarioService.findScenariosForUser(user, regionName);

        List<ScenarioSummaryDto> dtos = new ArrayList<>();
        for (Scenario s : scenarios) {
            ScenarioIndicator ind = s.getIndicator();
            dtos.add(ScenarioSummaryDto.builder()
                    .id(s.getId())
                    .name(s.getName())
                    .regionName(s.getRegionName())
                    .coverageTargetPct(s.getCoverageTargetPct())
                    .maxGateways(s.getMaxGateways())
                    .propagationModel(s.getPropagationModel())
                    .status(s.getStatus())
                    .totalCoveragePct(ind != null ? ind.getTotalCoveragePct() : null)
                    .usedGatewayCount(ind != null ? ind.getUsedGatewayCount() : null)
                    .totalEstimatedCost(ind != null ? ind.getTotalEstimatedCost() : null)
                    .processedAt(s.getProcessedAt())
                    .build());
        }
        return ResponseEntity.ok(dtos);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Obter detalhes de um cenário", description = "Retorna todos os dados de um cenário salvo, permitindo reabrir tela de resultados.", security = @SecurityRequirement(name = "Bearer Authentication"))
    public ResponseEntity<ScenarioDetailDto> getScenario(
            Authentication authentication,
            @PathVariable Long id) {

        authenticatedUser(authentication);
        Scenario scenario = scenarioService.getScenarioById(id);
        if (scenario == null) {
            return ResponseEntity.notFound().build();
        }

        ScenarioDetailDto dto = toDetailDto(scenario);
        List<ScenarioAssetLocation> locations = scenarioService.getAssetLocations(id);
        dto.setAssets(locations.stream()
                .map(l -> ScenarioDetailDto.AssetDto.builder()
                        .assetKey(l.assetKey())
                        .type(l.type())
                        .latitude(l.latitude())
                        .longitude(l.longitude())
                        .covered(l.covered())
                        .build())
                .toList());
        if (dto.getSelectedGateways() != null) {
            for (ScenarioDetailDto.SelectedGatewayDto gateway : dto.getSelectedGateways()) {
                gateway.setLinkedAssets((int) locations.stream()
                        .filter(l -> l.covered() && java.util.Objects.equals(l.gatewayCandidateId(), gateway.getCandidateId()))
                        .count());
            }
        }
        return ResponseEntity.ok(dto);
    }

    @PostMapping("/{id}/duplicate")
    @Operation(summary = "Duplicar cenário", description = "Cria uma cópia do cenário existente como base para nova simulação.", security = @SecurityRequirement(name = "Bearer Authentication"))
    public ResponseEntity<ScenarioSummaryDto> duplicateScenario(
            Authentication authentication,
            @PathVariable Long id,
            @RequestBody(required = false) Map<String, String> body) {

        User user = authenticatedUser(authentication);
        String newName = body != null ? body.get("name") : null;
        Scenario duplicated = scenarioService.duplicateScenario(id, user, newName);
        ScenarioSummaryDto dto = ScenarioSummaryDto.builder()
                .id(duplicated.getId())
                .name(duplicated.getName())
                .regionName(duplicated.getRegionName())
                .coverageTargetPct(duplicated.getCoverageTargetPct())
                .maxGateways(duplicated.getMaxGateways())
                .propagationModel(duplicated.getPropagationModel())
                .status(duplicated.getStatus())
                .build();
        return ResponseEntity.ok(dto);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Excluir cenário", description = "Remove um cenário salvo.", security = @SecurityRequirement(name = "Bearer Authentication"))
    public ResponseEntity<Void> deleteScenario(
            Authentication authentication,
            @PathVariable Long id) {

        User user = authenticatedUser(authentication);
        scenarioService.deleteScenario(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/compare")
    @Operation(summary = "Comparar cenários", description = "Retorna indicadores necessários para comparar dois ou mais cenários.", security = @SecurityRequirement(name = "Bearer Authentication"))
    public ResponseEntity<ScenarioComparisonResponse> compareScenarios(
            Authentication authentication,
            @Valid @RequestBody ScenarioComparisonRequest request) {

        User user = authenticatedUser(authentication);
        List<ScenarioSummaryDto> summaries = new ArrayList<>();
        Map<String, Object> comparison = new HashMap<>();

        for (Long id : request.getScenarioIds()) {
            Scenario s = scenarioService.getScenarioById(id);
            if (s == null) {
                return ResponseEntity.badRequest().body(null);
            }
            ScenarioIndicator ind = s.getIndicator();
            summaries.add(ScenarioSummaryDto.builder()
                    .id(s.getId())
                    .name(s.getName())
                    .regionName(s.getRegionName())
                    .coverageTargetPct(s.getCoverageTargetPct())
                    .maxGateways(s.getMaxGateways())
                    .propagationModel(s.getPropagationModel())
                    .status(s.getStatus())
                    .totalCoveragePct(ind != null ? ind.getTotalCoveragePct() : null)
                    .usedGatewayCount(ind != null ? ind.getUsedGatewayCount() : null)
                    .totalEstimatedCost(ind != null ? ind.getTotalEstimatedCost() : null)
                    .build());
        }

        comparison.put("count", summaries.size());
        ScenarioComparisonResponse response = ScenarioComparisonResponse.builder()
                .scenarios(summaries)
                .comparisonIndicators(comparison)
                .build();
        return ResponseEntity.ok(response);
    }

    private ScenarioDetailDto toDetailDto(Scenario scenario) {
        ScenarioIndicator ind = scenario.getIndicator();
        List<ScenarioDetailDto.SelectedGatewayDto> gateways = new ArrayList<>();
        if (scenario.getSelectedGateways() != null) {
            for (ScenarioSelectedGateway g : scenario.getSelectedGateways()) {
                gateways.add(ScenarioDetailDto.SelectedGatewayDto.builder()
                        .candidateId(g.getCandidateId())
                        .latitude(g.getCoordinate() != null ? g.getCoordinate().latitude() : null)
                        .longitude(g.getCoordinate() != null ? g.getCoordinate().longitude() : null)
                        .coverageRadiusMeters(g.getCoverageRadiusMeters())
                        .manuallyAdjusted(g.isManuallyAdjusted())
                        .assetKey(g.getAssetKey())
                        .coverageGeometryGeoJson(g.getCoverageGeometryGeoJson())
                        .coveredAssetCount(g.getCoveredAssetCount())
                        .averageRssiDbm(g.getAverageRssiDbm())
                        .averageLinkMarginDb(g.getAverageLinkMarginDb())
                        .shadowedAssetKeys(g.getShadowedAssetKeys())
                        .build());
            }
        }

        ScenarioDetailDto.ScenarioIndicatorDto indicatorDto = null;
        if (ind != null) {
            indicatorDto = ScenarioDetailDto.ScenarioIndicatorDto.builder()
                    .totalCoveragePct(ind.getTotalCoveragePct())
                    .coveragePctByAssetType(ind.getCoveragePctByAssetType())
                    .usedGatewayCount(ind.getUsedGatewayCount())
                    .totalEstimatedCost(ind.getTotalEstimatedCost())
                    .targetReached(ind.isTargetReached())
                    .build();
        }

        return ScenarioDetailDto.builder()
                .id(scenario.getId())
                .name(scenario.getName())
                .regionName(scenario.getRegionName())
                .areaWkt(scenario.getAreaWkt())
                .coverageTargetPct(scenario.getCoverageTargetPct())
                .maxGateways(scenario.getMaxGateways())
                .gatewayUnitCost(scenario.getGatewayUnitCost())
                .propagationModel(scenario.getPropagationModel())
                .rfParameter(scenario.getRfParameter())
                .status(scenario.getStatus())
                .processingTimeMs(scenario.getProcessingTimeMs())
                .processedAt(scenario.getProcessedAt())
                .selectedGateways(gateways)
                .indicator(indicatorDto)
                .averageRssiDbm(scenario.getAverageRssiDbm())
                .build();
    }
}
