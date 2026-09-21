package com.backend.tecsys;

import com.backend.tecsys.radio.exception.PropagationCalculationException;
import com.backend.tecsys.radio.model.PropagationInput;
import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.radio.service.FreeSpacePathLossModel;
import com.backend.tecsys.radio.service.PropagationModel;
import com.backend.tecsys.scenario.exception.InvalidSimulationParameterException;
import com.backend.tecsys.scenario.model.PropagationModelType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class FreeSpacePathLossModelTest {

    private PropagationModel model;

    @BeforeEach
    void setUp() {
        model = new FreeSpacePathLossModel();
    }

    @Test
    void shouldCalculateFreeSpacePathLoss() {
        PropagationInput input = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.001, -47.001),
                1000.0,
                6.0,
                5.0,
                null);

        double loss = model.calculatePropagationLossDb(input);

        /* FSPL = 20*log10(1000) + 20*log10(915) - 27.55 = 60 + 59.2284 - 27.55 = 91.6784 dB */
        assertEquals(91.68, loss, 0.05);
        assertEquals(PropagationModelType.FREE_SPACE, model.type());
    }

    @Test
    void shouldRejectNonPositiveFrequency() {
        PropagationInput input = new PropagationInput(
                0.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.001, -47.001),
                1000.0,
                6.0,
                5.0,
                null);

        assertThrows(InvalidSimulationParameterException.class,
                () -> model.calculatePropagationLossDb(input));
    }

    @Test
    void shouldRejectNonPositiveDistance() {
        PropagationInput input = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.0, -47.0),
                -5.0,
                6.0,
                5.0,
                null);

        assertThrows(PropagationCalculationException.class,
                () -> model.calculatePropagationLossDb(input));
    }
}
