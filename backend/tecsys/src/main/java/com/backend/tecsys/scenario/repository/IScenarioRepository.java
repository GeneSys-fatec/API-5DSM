package com.backend.tecsys.scenario.repository;

import com.backend.tecsys.scenario.model.Scenario;
import com.backend.tecsys.scenario.model.ScenarioAssetLocation;

import java.util.List;

public interface IScenarioRepository {

    Scenario save(Scenario scenario);

    Scenario findById(Long id);

    List<Scenario> findAllByUserId(Long userId);

    List<Scenario> findByUserIdAndRegionName(Long userId, String regionName);

    void deleteById(Long id);

    /** Ativos avaliados no cenário, com coordenadas, para reconstruir o mapa de resultados. */
    default List<ScenarioAssetLocation> findAssetLocations(Long scenarioId) {
        return List.of();
    }
}
