package com.backend.tecsys.radio.service;import com.backend.tecsys.radio.model.PropagationInput;
import com.backend.tecsys.radio.model.TerrainProfile;


import com.backend.tecsys.radio.exception.PropagationCalculationException;
import com.backend.tecsys.radio.exception.UnavailableTerrainDataException;
import com.backend.tecsys.scenario.model.PropagationModelType;
import org.springframework.stereotype.Component;

@Component
public class ItmLongleyRiceModel implements PropagationModel {

    private static final double SPEED_OF_LIGHT_M_S = 3.0e8;

    @Override
    public PropagationModelType type() {
        return PropagationModelType.ITM_LONGLEY_RICE;
    }

    @Override
    public double calculatePropagationLossDb(PropagationInput input) {
        TerrainProfile terrainProfile = input.terrainProfile();
        if (terrainProfile == null || !terrainProfile.isAvailable()) {
            throw new UnavailableTerrainDataException(
                    "Dados de relevo indisponíveis para o cálculo ITM (Longley-Rice). "
                            + "Informe um perfil de terreno para este cenário.");
        }

        double frequencyMhz = input.frequencyMhz();
        if (frequencyMhz <= 0) {
            throw new PropagationCalculationException(
                    "A frequência deve ser maior que zero para o cálculo de propagação.");
        }

        double distanceM = input.distanceM();
        if (distanceM <= 0) {
            throw new PropagationCalculationException(
                    "A distância deve ser maior que zero para o cálculo de propagação.");
        }

        double freeSpaceLoss = 32.44 + 20 * Math.log10(frequencyMhz) + 20 * Math.log10(distanceM / 1000.0);
        double terrainLoss = terrainDiffractionLossDb(input, terrainProfile);

        return freeSpaceLoss + terrainLoss;
    }

    private double terrainDiffractionLossDb(PropagationInput input, TerrainProfile terrainProfile) {
        double[] elevations = terrainProfile.elevationsMeters();
        int sampleCount = elevations.length;
        double sampleSpacingM = terrainProfile.sampleSpacingM();
        double distanceM = input.distanceM();
        double wavelengthM = SPEED_OF_LIGHT_M_S / (input.frequencyMhz() * 1.0e6);

        double gatewayHeight = elevations[0] + input.gatewayHeightM();
        double deviceHeight = elevations[sampleCount - 1] + input.deviceHeightM();

        double worstFresnelParameter = Double.NEGATIVE_INFINITY;

        for (int index = 1; index < sampleCount - 1; index++) {
            double distanceFromGateway = index * sampleSpacingM;
            double distanceToDevice = distanceM - distanceFromGateway;
            if (distanceFromGateway <= 0 || distanceToDevice <= 0) {
                continue;
            }

            double lineHeight = gatewayHeight
                    + (deviceHeight - gatewayHeight) * (distanceFromGateway / distanceM);
            double obstructionM = elevations[index] - lineHeight;
            if (obstructionM <= 0) {
                continue;
            }

            double fresnelParameter = obstructionM
                    * Math.sqrt((2 * (distanceFromGateway + distanceToDevice))
                    / (wavelengthM * distanceFromGateway * distanceToDevice));

            if (fresnelParameter > worstFresnelParameter) {
                worstFresnelParameter = fresnelParameter;
            }
        }

        if (worstFresnelParameter <= -0.78) {
            return 0.0;
        }

        return 6.9 + 20 * Math.log10(
                Math.sqrt(Math.pow(worstFresnelParameter - 0.1, 2) + 1) + worstFresnelParameter - 0.1);
    }
}
