package com.backend.tecsys.scenario.service;

public interface CostCalculator {

    double calculateTotalCost(int gatewayCount, Double gatewayUnitCost);
}
