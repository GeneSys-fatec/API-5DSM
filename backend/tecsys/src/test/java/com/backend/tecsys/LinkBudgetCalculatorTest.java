package com.backend.tecsys;

import com.backend.tecsys.radio.model.RfParameter;
import com.backend.tecsys.radio.service.LinkBudgetCalculator;
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

    @Test
    void shouldCalculateMaxPermissiblePathLoss() {
        double maxLoss = calculator.maxPermissiblePathLossDb(rfParameter);
        assertEquals(141.0, maxLoss, 0.001);

        RfParameter custom = RfParameter.builder()
                .transmitPowerDbm(21.0)
                .receiverSensitivityDbm(-120.0)
                .antennaGainDbi(2.15)
                .systemLossDb(1.0)
                .build();
        assertEquals(142.15, calculator.maxPermissiblePathLossDb(custom), 0.001);
    }

    @Test
    void shouldCalculateLinkMargin() {
        double margin = calculator.linkMarginDb(-96.0, rfParameter);
        assertEquals(24.0, margin, 0.001);

        double zeroMargin = calculator.linkMarginDb(-120.0, rfParameter);
        assertEquals(0.0, zeroMargin, 0.001);

        double negativeMargin = calculator.linkMarginDb(-125.0, rfParameter);
        assertEquals(-5.0, negativeMargin, 0.001);
    }

    @Test
    void shouldCheckPathLossCoverage() {
        assertTrue(calculator.isPathLossCovered(141.0, rfParameter));
        assertTrue(calculator.isPathLossCovered(100.0, rfParameter));
        assertFalse(calculator.isPathLossCovered(141.1, rfParameter));
    }
}
