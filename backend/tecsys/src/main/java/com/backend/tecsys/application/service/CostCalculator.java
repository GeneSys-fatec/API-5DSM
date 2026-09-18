package com.backend.tecsys.application.service;

public interface CostCalculator {

    double calculateTotalCost(int gatewayCount, Double gatewayUnitCost);
}
