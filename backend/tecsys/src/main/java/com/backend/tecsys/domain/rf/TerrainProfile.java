package com.backend.tecsys.domain.rf;

public record TerrainProfile(double[] elevationsMeters, double sampleSpacingM) {

    public boolean isAvailable() {
        return elevationsMeters != null && elevationsMeters.length >= 2 && sampleSpacingM > 0;
    }
}
