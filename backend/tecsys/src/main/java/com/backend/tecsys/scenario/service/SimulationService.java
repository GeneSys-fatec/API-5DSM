package com.backend.tecsys.scenario.service;

import com.backend.tecsys.radio.model.RfParameter;
import com.backend.tecsys.radio.service.PropagationModel;
import com.backend.tecsys.radio.service.PropagationModelRegistry;
import com.backend.tecsys.radio.service.RadioCoverageCalculator;
import com.backend.tecsys.scenario.exception.InvalidGatewayCandidateException;
import com.backend.tecsys.scenario.exception.InvalidSimulationParameterException;
import com.backend.tecsys.scenario.model.Asset;
import com.backend.tecsys.scenario.model.GatewayCandidate;
import com.backend.tecsys.scenario.model.GatewayCoverage;
import com.backend.tecsys.scenario.model.PropagationModelType;
import com.backend.tecsys.scenario.model.Scenario;
import com.backend.tecsys.scenario.model.ScenarioAssetCoverage;
import com.backend.tecsys.scenario.model.ScenarioIndicator;
import com.backend.tecsys.scenario.model.ScenarioSelectedGateway;
import com.backend.tecsys.scenario.repository.GatewayCandidateProvider;
import com.backend.tecsys.scenario.repository.IAssetRepository;
import com.backend.tecsys.scenario.repository.IScenarioRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

@Service
public class SimulationService {

    private final IAssetRepository assetRepository;
    private final GatewayCandidateProvider gatewayCandidateProvider;
    private final PropagationModelRegistry propagationModelRegistry;
    private final RadioCoverageCalculator radioCoverageCalculator;
    private final GatewaySelectionService gatewaySelectionService;
    private final ScenarioIndicatorCalculator scenarioIndicatorCalculator;
    private final CostCalculator costCalculator;
    private final IScenarioRepository scenarioRepository;

    public SimulationService(
            IAssetRepository assetRepository,
            GatewayCandidateProvider gatewayCandidateProvider,
            PropagationModelRegistry propagationModelRegistry,
            RadioCoverageCalculator radioCoverageCalculator,
            GatewaySelectionService gatewaySelectionService,
            ScenarioIndicatorCalculator scenarioIndicatorCalculator,
            CostCalculator costCalculator,
            IScenarioRepository scenarioRepository) {
        this.assetRepository = assetRepository;
        this.gatewayCandidateProvider = gatewayCandidateProvider;
        this.propagationModelRegistry = propagationModelRegistry;
        this.radioCoverageCalculator = radioCoverageCalculator;
        this.gatewaySelectionService = gatewaySelectionService;
        this.scenarioIndicatorCalculator = scenarioIndicatorCalculator;
        this.costCalculator = costCalculator;
        this.scenarioRepository = scenarioRepository;
    }

    public SimulationOutcome simulate(SimulationCommand command, Long userId, Long utilityId) {
        validate(command);

        long startedAt = System.currentTimeMillis();

        List<Asset> assets = assetRepository.findByUtilityId(utilityId);
        if (assets.isEmpty()) {
            throw new InvalidSimulationParameterException(
                    "Nenhum ativo encontrado para a distribuidora informada.");
        }

        List<GatewayCandidate> candidates = new ArrayList<>(gatewayCandidateProvider.getCandidates(utilityId));
        if (candidates.isEmpty()) {
            throw new InvalidGatewayCandidateException(
                    "Nenhum candidato a gateway foi encontrado para a região informada.");
        }

        PropagationModel propagationModel = propagationModelRegistry.resolve(command.propagationModel());

        List<GatewayCoverage> individualCoverages = new ArrayList<>();
        for (GatewayCandidate candidate : candidates) {
            individualCoverages.add(radioCoverageCalculator.calculateCoverage(
                    candidate, assets, command.rfParameter(), propagationModel));
        }

        GatewaySelectionService.SelectionResult selection = gatewaySelectionService.select(
                individualCoverages,
                assets.size(),
                command.coverageTargetPct(),
                command.maxGateways());

        Set<String> coveredAssetKeys = selection.coveredAssetKeys();
        List<ScenarioSelectedGateway> selectedGateways = buildSelectedGateways(selection.selectedCoverages());
        List<ScenarioAssetCoverage> assetCoverages = buildAssetCoverages(assets, coveredAssetKeys, selection.selectedCoverages());

        int processingTimeMs = (int) (System.currentTimeMillis() - startedAt);
        double totalEstimatedCost = costCalculator.calculateTotalCost(
                selectedGateways.size(), command.gatewayUnitCost());

        ScenarioIndicator indicator = scenarioIndicatorCalculator.calculate(
                assets,
                coveredAssetKeys,
                selectedGateways.size(),
                totalEstimatedCost,
                processingTimeMs,
                selection.targetReached());

        Scenario scenario = Scenario.builder()
                .name(command.scenarioName())
                .userId(userId)
                .utilityId(utilityId)
                .regionName(command.regionName())
                .coverageTargetPct(command.coverageTargetPct())
                .maxGateways(command.maxGateways())
                .gatewayUnitCost(command.gatewayUnitCost() != null
                        ? command.gatewayUnitCost()
                        : MockCostCalculator.DEFAULT_GATEWAY_UNIT_COST)
                .propagationModel(command.propagationModel())
                .status("concluido")
                .processingTimeMs(processingTimeMs)
                .selectedGateways(selectedGateways)
                .assetCoverages(assetCoverages)
                .indicator(indicator)
                .build();

        scenarioRepository.save(scenario);

        List<String> coveredAssetKeysResult = new ArrayList<>();
        List<String> uncoveredAssetKeysResult = new ArrayList<>();
        for (Asset asset : assets) {
            if (coveredAssetKeys.contains(asset.getAssetKey())) {
                coveredAssetKeysResult.add(asset.getAssetKey());
            } else {
                uncoveredAssetKeysResult.add(asset.getAssetKey());
            }
        }

        List<GatewayCandidate> selectedCandidates = new ArrayList<>();
        for (GatewayCoverage coverage : selection.selectedCoverages()) {
            selectedCandidates.add(coverage.getCandidate());
        }

        double coverageRadiusMeters = selection.selectedCoverages().isEmpty()
                ? radioCoverageCalculator.calculateCoverageRadius(command.rfParameter(), propagationModel)
                : selection.selectedCoverages().get(0).getCoverageRadiusMeters();

        return new SimulationOutcome(
                scenario.getId(),
                scenario.getStatus(),
                command.propagationModel(),
                command.rfParameter(),
                selectedCandidates,
                coveredAssetKeysResult,
                uncoveredAssetKeysResult,
                indicator,
                coverageRadiusMeters);
    }

    private void validate(SimulationCommand command) {
        if (command.scenarioName() == null || command.scenarioName().isBlank()) {
            throw new InvalidSimulationParameterException("O nome do cenário é obrigatório.");
        }

        if (command.coverageTargetPct() < 1.0 || command.coverageTargetPct() > 100.0) {
            throw new InvalidSimulationParameterException(
                    "A meta de cobertura deve estar entre 1% e 100%.");
        }

        if (command.maxGateways() < 1) {
            throw new InvalidSimulationParameterException(
                    "A quantidade máxima de gateways deve ser maior ou igual a 1.");
        }

        RfParameter rfParameter = command.rfParameter();
        if (rfParameter.getFrequencyMhz() <= 0) {
            throw new InvalidSimulationParameterException("A frequência deve ser maior que zero.");
        }
        if (rfParameter.getTransmitPowerDbm() <= 0) {
            throw new InvalidSimulationParameterException("A potência de transmissão deve ser maior que zero.");
        }
        if (rfParameter.getReceiverSensitivityDbm() >= 0) {
            throw new InvalidSimulationParameterException("A sensibilidade do receptor deve ser menor que zero.");
        }
        if (rfParameter.getAntennaHeightM() <= 0) {
            throw new InvalidSimulationParameterException("A altura do gateway deve ser maior que zero.");
        }
        if (rfParameter.getDeviceHeightM() <= 0) {
            throw new InvalidSimulationParameterException("A altura do dispositivo deve ser maior que zero.");
        }
    }

    private List<ScenarioSelectedGateway> buildSelectedGateways(List<GatewayCoverage> selectedCoverages) {
        List<ScenarioSelectedGateway> selectedGateways = new ArrayList<>();
        int order = 0;

        for (GatewayCoverage coverage : selectedCoverages) {
            selectedGateways.add(ScenarioSelectedGateway.builder()
                    .candidateId(coverage.getCandidate().getId())
                    .coordinate(coverage.getCandidate().getCoordinate())
                    .coverageRadiusMeters(coverage.getCoverageRadiusMeters())
                    .manuallyAdjusted(false)
                    .selectionOrder(++order)
                    .build());
        }

        return selectedGateways;
    }

    private List<ScenarioAssetCoverage> buildAssetCoverages(
            List<Asset> assets,
            Set<String> coveredAssetKeys,
            List<GatewayCoverage> selectedCoverages) {

        List<ScenarioAssetCoverage> assetCoverages = new ArrayList<>();
        Set<String> covered = new LinkedHashSet<>(coveredAssetKeys);

        for (Asset asset : assets) {
            boolean isCovered = covered.contains(asset.getAssetKey());
            Long selectedCandidateId = null;

            if (isCovered) {
                for (GatewayCoverage coverage : selectedCoverages) {
                    if (coverage.covers(asset.getAssetKey())) {
                        selectedCandidateId = coverage.getCandidate().getId();
                        break;
                    }
                }
            }

            assetCoverages.add(ScenarioAssetCoverage.builder()
                    .assetKey(asset.getAssetKey())
                    .covered(isCovered)
                    .selectedCandidateId(selectedCandidateId)
                    .build());
        }

        return assetCoverages;
    }

    public record SimulationCommand(
            String scenarioName,
            String regionName,
            double coverageTargetPct,
            int maxGateways,
            Double gatewayUnitCost,
            PropagationModelType propagationModel,
            RfParameter rfParameter) {
    }

    public record SimulationOutcome(
            Long scenarioId,
            String status,
            PropagationModelType propagationModel,
            RfParameter rfParameter,
            List<GatewayCandidate> selectedGateways,
            List<String> coveredAssetKeys,
            List<String> uncoveredAssetKeys,
            ScenarioIndicator indicator,
            double coverageRadiusMeters) {

        public SimulationOutcome(
                Long scenarioId,
                String status,
                PropagationModelType propagationModel,
                RfParameter rfParameter,
                List<GatewayCandidate> selectedGateways,
                List<String> coveredAssetKeys,
                List<String> uncoveredAssetKeys,
                ScenarioIndicator indicator) {
            this(scenarioId, status, propagationModel, rfParameter, selectedGateways,
                    coveredAssetKeys, uncoveredAssetKeys, indicator, 0.0);
        }
    }
}
