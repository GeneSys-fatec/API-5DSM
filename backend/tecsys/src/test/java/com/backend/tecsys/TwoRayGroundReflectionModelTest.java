package com.backend.tecsys;

import com.backend.tecsys.radio.exception.PropagationCalculationException;
import com.backend.tecsys.radio.model.PropagationInput;
import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.radio.service.TwoRayGroundReflectionModel;
import com.backend.tecsys.scenario.exception.InvalidSimulationParameterException;
import com.backend.tecsys.scenario.model.PropagationModelType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class TwoRayGroundReflectionModelTest {

    private TwoRayGroundReflectionModel model;

    @BeforeEach
    void setUp() {
        model = new TwoRayGroundReflectionModel();
    }

    @Test
    void shouldReportCorrectModelType() {
        assertEquals(PropagationModelType.TWO_RAY_GROUND, model.type());
    }

    @Test
    void shouldCalculateBreakpointDistance() {
        double breakpoint = model.calculateBreakpointDistanceM(915.0, 6.0, 5.0);
        assertEquals(1150.6, breakpoint, 1.0);
    }

    @Test
    void shouldFollowFreeSpaceBeforeBreakpoint() {
        PropagationInput input = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.001, -47.001),
                500.0,
                6.0,
                5.0,
                null);

        double loss = model.calculatePropagationLossDb(input);
        assertEquals(85.66, loss, 0.05);
    }

    @Test
    void shouldFollowTwoRayFormulaAfterBreakpoint() {
        PropagationInput input = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.001, -47.001),
                2000.0,
                6.0,
                5.0,
                null);

        double loss = model.calculatePropagationLossDb(input);
        assertEquals(102.50, loss, 0.05);
    }

    @Test
    void shouldDecreasePathLossWhenGatewayHeightIncreases() {
        PropagationInput lowerGw = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.001, -47.001),
                4000.0,
                6.0,
                5.0,
                null);

        PropagationInput higherGw = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.001, -47.001),
                4000.0,
                12.0,
                5.0,
                null);

        double lossLower = model.calculatePropagationLossDb(lowerGw);
        double lossHigher = model.calculatePropagationLossDb(higherGw);

        assertTrue(lossHigher < lossLower);
        assertEquals(6.02, lossLower - lossHigher, 0.05);
    }

    @Test
    void shouldDecreasePathLossWhenDeviceHeightIncreases() {
        PropagationInput lowerDev = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.001, -47.001),
                4000.0,
                6.0,
                5.0,
                null);

        PropagationInput higherDev = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.001, -47.001),
                4000.0,
                6.0,
                10.0,
                null);

        double lossLower = model.calculatePropagationLossDb(lowerDev);
        double lossHigher = model.calculatePropagationLossDb(higherDev);

        assertTrue(lossHigher < lossLower);
        assertEquals(6.02, lossLower - lossHigher, 0.05);
    }

    @Test
    void shouldRejectInvalidHeights() {
        PropagationInput zeroGwHeight = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.001, -47.001),
                1000.0,
                0.0,
                5.0,
                null);

        assertThrows(InvalidSimulationParameterException.class,
                () -> model.calculatePropagationLossDb(zeroGwHeight));

        PropagationInput negativeDevHeight = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.001, -47.001),
                1000.0,
                6.0,
                -1.0,
                null);

        assertThrows(InvalidSimulationParameterException.class,
                () -> model.calculatePropagationLossDb(negativeDevHeight));
    }

    @Test
    void shouldRejectInvalidFrequencyAndDistance() {
        PropagationInput negativeFreq = new PropagationInput(
                -10.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.001, -47.001),
                1000.0,
                6.0,
                5.0,
                null);

        assertThrows(InvalidSimulationParameterException.class,
                () -> model.calculatePropagationLossDb(negativeFreq));

        PropagationInput zeroDist = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.0, -47.0),
                0.0,
                6.0,
                5.0,
                null);

        assertThrows(PropagationCalculationException.class,
                () -> model.calculatePropagationLossDb(zeroDist));
    }
}
