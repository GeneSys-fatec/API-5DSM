package com.backend.tecsys;

import com.backend.tecsys.domain.model.RfParameter;
import com.backend.tecsys.domain.rf.LinkBudgetCalculator;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class LinkBudgetCalculatorTest {

    private final LinkBudgetCalculator calculator = new LinkBudgetCalculator();
    private final RfParameter rfParameter = RfParameter.defaults();

    @Test
    void shouldCalculateReceivedPower() {
        double receivedPower = calculator.receivedPowerDbm(rfParameter, 117.0);

        assertEquals(-96.0, receivedPower, 0.001);
    }

    @Test
    void shouldMarkAssetAsCoveredWhenReceivedPowerReachesSensitivity() {
        assertTrue(calculator.isCovered(-120.0, rfParameter));
        assertTrue(calculator.isCovered(-96.0, rfParameter));
    }

    @Test
    void shouldMarkAssetAsNotCoveredWhenReceivedPowerIsBelowSensitivity() {
        assertFalse(calculator.isCovered(-120.1, rfParameter));
    }
}
