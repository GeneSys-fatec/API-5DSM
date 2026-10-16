package com.backend.tecsys.radio.service;

import com.backend.tecsys.radio.model.PropagationInput;
import com.backend.tecsys.radio.model.TerrainProfile;
import org.springframework.stereotype.Component;

@Component
public class TerrainLineOfSightAnalyzer {
    private static final double EARTH_RADIUS_M = 6_371_000.0;
    private static final double EARTH_REFRACTION_FACTOR = 4.0 / 3.0;
    private static final double SPEED_OF_LIGHT_M_S = 299_792_458.0;
    private static final double FRESNEL_CLEARANCE_FACTOR = 0.6;

    public TerrainEvaluation evaluate(PropagationInput input) {
        TerrainProfile profile = input.terrainProfile();
        if (profile == null || !profile.isAvailable()) {
            return TerrainEvaluation.unavailable();
        }

        double[] elevations = profile.elevationsMeters();
        double distance = input.distanceM();
        double effectiveRadius = EARTH_RADIUS_M * EARTH_REFRACTION_FACTOR;
        double wavelength = SPEED_OF_LIGHT_M_S / (input.frequencyMhz() * 1_000_000.0);
        double gatewayGround = elevations[0];
        double deviceGround = elevations[elevations.length - 1];
        double gatewayTop = gatewayGround + input.gatewayHeightM();
        double deviceTop = deviceGround + input.deviceHeightM();
        double maximumObstruction = 0.0;
        double minimumFresnelClearance = Double.POSITIVE_INFINITY;

        for (int index = 1; index < elevations.length - 1; index++) {
            double d1 = Math.min(index * profile.sampleSpacingM(), distance);
            double d2 = Math.max(distance - d1, 0.0);
            if (d1 <= 0.0 || d2 <= 0.0) {
                continue;
            }

            double line = gatewayTop + (deviceTop - gatewayTop) * (d1 / distance);
            double earthBulge = d1 * d2 / (2.0 * effectiveRadius);
            double obstruction = elevations[index] + earthBulge - line;
            maximumObstruction = Math.max(maximumObstruction, obstruction);

            double firstFresnelRadius = Math.sqrt(wavelength * d1 * d2 / distance);
            double clearance = line - earthBulge - elevations[index] - FRESNEL_CLEARANCE_FACTOR * firstFresnelRadius;
            minimumFresnelClearance = Math.min(minimumFresnelClearance, clearance);
        }

        boolean lineOfSight = maximumObstruction <= 0.0;
        boolean fresnelClear = minimumFresnelClearance >= 0.0;
        return new TerrainEvaluation(true, lineOfSight, fresnelClear,
                maximumObstruction, minimumFresnelClearance);
    }

    public record TerrainEvaluation(
            boolean available,
            boolean lineOfSight,
            boolean fresnelClear,
            double maximumObstructionM,
            double minimumFresnelClearanceM) {
        static TerrainEvaluation unavailable() {
            return new TerrainEvaluation(false, true, true, 0.0, Double.POSITIVE_INFINITY);
        }

        public boolean coveredByTerrain() {
            return !available || (lineOfSight && fresnelClear);
        }

        public boolean shadowed() {
            return available && !coveredByTerrain();
        }
    }
}
