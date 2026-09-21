package com.backend.tecsys.radio.model;

import com.backend.tecsys.radio.model.RfCoordinate;

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
