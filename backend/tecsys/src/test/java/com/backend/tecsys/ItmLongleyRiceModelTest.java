package com.backend.tecsys;

import com.backend.tecsys.radio.exception.UnavailableTerrainDataException;
import com.backend.tecsys.scenario.model.PropagationModelType;
import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.radio.service.ItmLongleyRiceModel;
import com.backend.tecsys.radio.model.PropagationInput;
import com.backend.tecsys.radio.service.PropagationModel;
import com.backend.tecsys.radio.model.TerrainProfile;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ItmLongleyRiceModelTest {

    private static final double FREE_SPACE_LOSS_DB = 91.67;

    private PropagationModel model;

    @BeforeEach
    void setUp() {
        model = new ItmLongleyRiceModel();
    }

    @Test
    void shouldThrowWhenTerrainProfileIsUnavailable() {
        PropagationInput input = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.001, -47.001),
                1000.0,
                6.0,
                5.0,
                null);

        assertThrows(UnavailableTerrainDataException.class,
                () -> model.calculatePropagationLossDb(input));
    }

    @Test
    void shouldCalculateItmLongleyRicePropagationLossWithTerrain() {
        TerrainProfile terrainProfile = new TerrainProfile(new double[]{0.0, 50.0, 0.0}, 500.0);

        PropagationInput input = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.001, -47.001),
                1000.0,
                6.0,
                5.0,
                terrainProfile);

        double loss = model.calculatePropagationLossDb(input);

        assertTrue(loss > FREE_SPACE_LOSS_DB,
                "A perda com obstáculo de relevo deve ser maior que a perda no espaço livre.");
        assertEquals(PropagationModelType.ITM_LONGLEY_RICE, model.type());
    }

    @Test
    void shouldReturnFreeSpaceLossWhenTerrainHasNoObstruction() {
        TerrainProfile flatTerrain = new TerrainProfile(new double[]{0.0, 0.0, 0.0}, 500.0);

        PropagationInput input = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.001, -47.001),
                1000.0,
                6.0,
                5.0,
                flatTerrain);

        assertEquals(FREE_SPACE_LOSS_DB, model.calculatePropagationLossDb(input), 0.1);
    }
}
