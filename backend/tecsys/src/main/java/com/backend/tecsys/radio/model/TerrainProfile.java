package com.backend.tecsys.radio.model;

public record TerrainProfile(double[] elevationsMeters, double sampleSpacingM) {

    public static TerrainProfile empty() {
        return new TerrainProfile(new double[0], 0.0);
    }

    public boolean isAvailable() {
        return elevationsMeters != null && elevationsMeters.length >= 2 && sampleSpacingM > 0;
    }
}
