package com.backend.tecsys;

import com.backend.tecsys.domain.exception.InvalidSimulationParameterException;
import com.backend.tecsys.domain.exception.PropagationCalculationException;
import com.backend.tecsys.domain.model.RfCoordinate;
import com.backend.tecsys.domain.rf.OkumuraHataSuburbanModel;
import com.backend.tecsys.domain.rf.PropagationInput;
import com.backend.tecsys.domain.rf.PropagationModel;
import com.backend.tecsys.domain.model.PropagationModelType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class OkumuraHataSuburbanModelTest {

    private PropagationModel model;

    @BeforeEach
    void setUp() {
        model = new OkumuraHataSuburbanModel();
    }

    @Test
    void shouldCalculateOkumuraHataSuburbanPropagationLoss() {
        PropagationInput input = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.001, -47.001),
                1000.0,
                6.0,
                5.0,
                null);

        double loss = model.calculatePropagationLossDb(input);

        assertEquals(117.31, loss, 0.5);
        assertEquals(PropagationModelType.OKUMURA_HATA_SUBURBAN, model.type());
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
    void shouldRejectNonPositiveDistance() {
        PropagationInput input = new PropagationInput(
                915.0,
                new RfCoordinate(-22.0, -47.0),
                new RfCoordinate(-22.0, -47.0),
                0.0,
                6.0,
                5.0,
                null);

        assertThrows(PropagationCalculationException.class,
                () -> model.calculatePropagationLossDb(input));
    }
}
