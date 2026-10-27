package com.backend.tecsys.scenario.service;

import com.backend.tecsys.auth.model.User;
import com.backend.tecsys.scenario.model.*;
import com.backend.tecsys.scenario.repository.IScenarioRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ScenarioService {

    private final IScenarioRepository scenarioRepository;

    public ScenarioService(IScenarioRepository scenarioRepository) {
        this.scenarioRepository = scenarioRepository;
    }

    public List<Scenario> findScenariosForUser(User user, String regionName) {
        if (regionName != null && !regionName.isBlank()) {
            return scenarioRepository.findByUserIdAndRegionName(user.getId(), regionName);
        }
        return scenarioRepository.findAllByUserId(user.getId());
    }

    public Scenario getScenarioById(Long id) {
        return scenarioRepository.findById(id);
    }

    public List<ScenarioAssetLocation> getAssetLocations(Long scenarioId) {
        return scenarioRepository.findAssetLocations(scenarioId);
    }

    public void deleteScenario(Long id) {
        scenarioRepository.deleteById(id);
    }

    public Scenario duplicateScenario(Long scenarioId, User user, String newName) {
        Scenario original = scenarioRepository.findById(scenarioId);
        if (original == null) {
            throw new IllegalArgumentException("Cenário não encontrado.");
        }
        Scenario copy = Scenario.builder()
                .name(newName != null ? newName : original.getName() + " (cópia)")
                .userId(user.getId())
                .utilityId(original.getUtilityId())
                .regionName(original.getRegionName())
                .coverageTargetPct(original.getCoverageTargetPct())
                .maxGateways(original.getMaxGateways())
                .gatewayUnitCost(original.getGatewayUnitCost())
                .propagationModel(original.getPropagationModel())
                .status("rascunho")
                .areaWkt(original.getAreaWkt())
                .rfParameter(original.getRfParameter())
                .coverageRadiusMeters(original.getCoverageRadiusMeters())
                .build();

        return scenarioRepository.save(copy);
    }
}
