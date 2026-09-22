package com.backend.tecsys.scenario.model;import com.backend.tecsys.radio.model.RfCoordinate;


import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GatewayCandidate {
    private Long id;
    private String source;
    private String assetKey;
    private Long utilityId;
    private RfCoordinate coordinate;
    private Double estimatedCost;
}
