package com.backend.tecsys.scenario.repository;

import com.backend.tecsys.scenario.model.Scenario;
import com.backend.tecsys.scenario.model.ScenarioAssetCoverage;
import com.backend.tecsys.scenario.model.ScenarioSelectedGateway;
import com.backend.tecsys.scenario.repository.IScenarioRepository;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Repository;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

@Repository
@Profile("mock")
public class MockScenarioRepository implements IScenarioRepository {

    private final Map<Long, Scenario> scenarios = new ConcurrentHashMap<>();
    private final AtomicLong scenarioIdGenerator = new AtomicLong(0);
    private final AtomicLong selectedGatewayIdGenerator = new AtomicLong(0);

    @Override
    public Scenario save(Scenario scenario) {
        Long scenarioId = scenarioIdGenerator.incrementAndGet();
        scenario.setId(scenarioId);

        Map<Long, Long> selectedGatewayIdByCandidate = new HashMap<>();
        for (ScenarioSelectedGateway gateway : scenario.getSelectedGateways()) {
            Long selectedGatewayId = selectedGatewayIdGenerator.incrementAndGet();
            gateway.setId(selectedGatewayId);
            gateway.setScenarioId(scenarioId);
            selectedGatewayIdByCandidate.put(gateway.getCandidateId(), selectedGatewayId);
        }

        for (ScenarioAssetCoverage coverage : scenario.getAssetCoverages()) {
            coverage.setScenarioId(scenarioId);
            coverage.setSelectedGatewayId(selectedGatewayIdByCandidate.get(coverage.getSelectedCandidateId()));
        }

        if (scenario.getIndicator() != null) {
            scenario.getIndicator().setScenarioId(scenarioId);
        }

        scenarios.put(scenarioId, scenario);
        return scenario;
    }
}
