package com.backend.tecsys.scenario.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Positive;

public record ScenarioReportRequest(
        @NotBlank String scenarioName,
        String regionName,
        @NotBlank String mapImageBase64,
        @NotBlank String propagationModel,
        @Positive Double frequencyMhz,
        Double txPowerDbm,
        Double antennaGainDbi,
        Double receiverSensitivityDbm,
        Double antennaHeightM,
        Double deviceHeightM,
        Double systemLossDb,
        @DecimalMin("0.0") @DecimalMax("100.0") Double coverageTargetPct,
        @Positive Integer maxGateways,
        @NotNull @DecimalMin("0.0") Double totalCoveragePct,
        @NotNull @Min(0) Integer gatewayCount,
        @NotNull @Min(0) Integer totalAssetCount,
        @NotNull @Min(0) Integer connectedAssetCount,
        @NotNull @Min(0) Integer shadowedAssetCount,
        @NotNull @DecimalMin("0.0") Double totalEstimatedCost,
        Double averageRssiDbm,
        @DecimalMin("0.0") Double gatewayUnitCost,
        Double searchRadiusMeters) {
}
