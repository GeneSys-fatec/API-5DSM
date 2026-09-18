package com.backend.tecsys;

import com.backend.tecsys.domain.exception.InvalidSimulationParameterException;
import com.backend.tecsys.domain.model.PropagationModelType;
import com.backend.tecsys.domain.model.RfCoordinate;
import com.backend.tecsys.domain.rf.PropagationInput;
import com.backend.tecsys.domain.rf.PropagationModel;
import com.backend.tecsys.domain.rf.ThreeGppRuralMacroModel;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class ThreeGppRuralMacroModelTest {

    private PropagationModel model;

    @BeforeEach
    void setUp() {
        model = new ThreeGppRuralMacroModel();
    }

    @Test
    void shouldCalculateThreeGppRuralMacroPropagationLoss() {
        PropagationInput input = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.001, -47.001),
                1000.0,
                6.0,
                5.0,
                null);

        double loss = model.calculatePropagationLossDb(input);

        assertEquals(93.80, loss, 0.5);
        assertEquals(PropagationModelType.THREE_GPP_RURAL_MACRO, model.type());
    }

    @Test
    void shouldRejectFrequencyOutOfRange() {
        PropagationInput input = new PropagationInput(
                100.0,
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
    void shouldRejectDistanceOutOfRange() {
        PropagationInput input = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.001, -47.001),
                5.0,
                6.0,
                5.0,
                null);

        assertThrows(InvalidSimulationParameterException.class,
                () -> model.calculatePropagationLossDb(input));
    }
}
