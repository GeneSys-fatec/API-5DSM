package com.backend.tecsys.scenario.repository;

import com.backend.tecsys.scenario.model.Scenario;

import java.util.List;

public interface IScenarioRepository {

    Scenario save(Scenario scenario);

    Scenario findById(Long id);

    List<Scenario> findAllByUserId(Long userId);

    List<Scenario> findByUserIdAndRegionName(Long userId, String regionName);

    void deleteById(Long id);
}
