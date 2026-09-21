package com.backend.tecsys;

import com.backend.tecsys.scenario.service.MockCostCalculator;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class MockCostCalculatorTest {

    private final MockCostCalculator calculator = new MockCostCalculator();

    @Test
    void shouldUseDefaultUnitCostWhenNotInformed() {
        assertEquals(4500.0, calculator.calculateTotalCost(3, null), 0.001);
    }

    @Test
    void shouldUseInformedUnitCost() {
        assertEquals(1000.0, calculator.calculateTotalCost(2, 500.0), 0.001);
    }
}
