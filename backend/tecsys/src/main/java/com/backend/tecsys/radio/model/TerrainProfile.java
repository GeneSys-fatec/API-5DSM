package com.backend.tecsys.radio.model;

public record TerrainProfile(double[] elevationsMeters, double sampleSpacingM) {

    public boolean isAvailable() {
        return elevationsMeters != null && elevationsMeters.length >= 2 && sampleSpacingM > 0;
    }
}
