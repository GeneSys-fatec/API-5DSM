package com.backend.tecsys.domain.rf;

import com.backend.tecsys.domain.model.RfCoordinate;

public record PropagationInput(
        double frequencyMhz,
        RfCoordinate gatewayCoordinate,
        RfCoordinate deviceCoordinate,
        double distanceM,
        double gatewayHeightM,
        double deviceHeightM,
        TerrainProfile terrainProfile) {

    public double distanceKm() {
        return distanceM / 1000.0;
    }

    public double frequencyGhz() {
        return frequencyMhz / 1000.0;
    }
}
