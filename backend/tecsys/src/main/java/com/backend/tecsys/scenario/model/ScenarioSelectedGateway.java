package com.backend.tecsys.scenario.model;

import com.backend.tecsys.radio.model.RfCoordinate;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScenarioSelectedGateway {
    private Long id;
    private Long scenarioId;
    private Long candidateId;
    private RfCoordinate coordinate;
    private double coverageRadiusMeters;
    private boolean manuallyAdjusted;
    private int selectionOrder;
}
