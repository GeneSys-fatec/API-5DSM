package com.backend.tecsys.scenario.model;

import com.backend.tecsys.radio.model.RfParameter;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Scenario {
    private Long id;
    private String name;
    private Long userId;
    private Long utilityId;
    private String regionName;
    private double coverageTargetPct;
    private int maxGateways;
    private Double gatewayUnitCost;
    private PropagationModelType propagationModel;
    private String status;
    private Integer processingTimeMs;
    private Instant processedAt;
    private String areaWkt;
    private RfParameter rfParameter;
    private Long rfParameterId;
    private Double coverageRadiusMeters;
    private Double averageRssiDbm;

    @Builder.Default
    private List<ScenarioSelectedGateway> selectedGateways = new ArrayList<>();

    @Builder.Default
    private List<ScenarioAssetCoverage> assetCoverages = new ArrayList<>();

    private ScenarioIndicator indicator;
}
