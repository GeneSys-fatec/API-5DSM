package com.backend.tecsys.scenario.service;

import org.springframework.stereotype.Service;

@Service
public class MockCostCalculator implements CostCalculator {

    public static final double DEFAULT_GATEWAY_UNIT_COST = 1500.0;

    @Override
    public double calculateTotalCost(int gatewayCount, Double gatewayUnitCost) {
        double unitCost = gatewayUnitCost != null ? gatewayUnitCost : DEFAULT_GATEWAY_UNIT_COST;
        return gatewayCount * unitCost;
    }
}
