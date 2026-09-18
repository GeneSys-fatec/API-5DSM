package com.backend.tecsys.domain.model;

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
    private boolean manuallyAdjusted;
    private int selectionOrder;
}
