package com.backend.tecsys.radio.service;

import com.backend.tecsys.radio.model.PropagationInput;
import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.radio.model.TerrainProfile;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class TerrainLineOfSightAnalyzerTest {
    private final TerrainLineOfSightAnalyzer analyzer = new TerrainLineOfSightAnalyzer();

    @Test
    void classifiesAProfileWithAnObstacleAsShadow() {
        PropagationInput input = new PropagationInput(
                915.0,
                new RfCoordinate(-23.0, -47.0),
                new RfCoordinate(-23.0, -46.99),
                1_000.0,
                6.0,
                5.0,
                new TerrainProfile(new double[]{100.0, 180.0, 100.0}, 500.0));

        assertTrue(analyzer.evaluate(input).available());
        assertTrue(analyzer.evaluate(input).shadowed());
    }

    @Test
    void acceptsAFlatProfileWithAValidFresnelClearance() {
        PropagationInput input = new PropagationInput(
                915.0,
                new RfCoordinate(-23.0, -47.0),
                new RfCoordinate(-23.0, -46.99),
                1_000.0,
                30.0,
                10.0,
                new TerrainProfile(new double[]{100.0, 100.0, 100.0}, 500.0));

        assertTrue(analyzer.evaluate(input).coveredByTerrain());
        assertFalse(analyzer.evaluate(input).shadowed());
    }
}