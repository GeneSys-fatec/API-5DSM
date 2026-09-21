package com.backend.tecsys.scenario.repository;

import com.backend.tecsys.scenario.model.GatewayCandidate;
import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.scenario.repository.GatewayCandidateProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

@Component
@Profile("mock")
public class MockGatewayCandidateProvider implements GatewayCandidateProvider {

    private static final double BASE_LATITUDE = -22.0000;
    private static final double BASE_LONGITUDE = -47.0000;
    private static final double GRID_STEP_DEGREES = 0.0050;
    private static final int COLUMNS = 3;

    private final int candidateCount;

    public MockGatewayCandidateProvider(
            @Value("${simulation.mock.candidate-count:5}") int candidateCount) {
        this.candidateCount = Math.max(1, candidateCount);
    }

    @Override
    public List<GatewayCandidate> getCandidates(Long utilityId) {
        List<GatewayCandidate> candidates = new ArrayList<>();

        for (int index = 0; index < candidateCount; index++) {
            int row = index / COLUMNS;
            int column = index % COLUMNS;

            double latitude = BASE_LATITUDE + row * GRID_STEP_DEGREES;
            double longitude = BASE_LONGITUDE + column * GRID_STEP_DEGREES;

            candidates.add(GatewayCandidate.builder()
                    .id((long) (index + 1))
                    .source("bdgd")
                    .assetKey("CANDIDATE-" + (index + 1))
                    .utilityId(utilityId)
                    .coordinate(new RfCoordinate(latitude, longitude))
                    .estimatedCost(1500.0)
                    .build());
        }

        return candidates;
    }
}
