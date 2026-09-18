package com.backend.tecsys.domain.rf;

import com.backend.tecsys.domain.exception.InvalidSimulationParameterException;
import com.backend.tecsys.domain.exception.PropagationCalculationException;
import com.backend.tecsys.domain.model.PropagationModelType;
import org.springframework.stereotype.Component;

@Component
public class ThreeGppRuralMacroModel implements PropagationModel {

    private static final double MIN_FREQUENCY_GHZ = 0.5;
    private static final double MAX_FREQUENCY_GHZ = 30.0;
    private static final double MIN_DISTANCE_M = 10.0;
    private static final double MAX_DISTANCE_M = 10000.0;
    private static final double AVERAGE_BUILDING_HEIGHT_M = 5.0;

    @Override
    public PropagationModelType type() {
        return PropagationModelType.THREE_GPP_RURAL_MACRO;
    }

    @Override
    public double calculatePropagationLossDb(PropagationInput input) {
        double frequencyGhz = input.frequencyGhz();
        if (frequencyGhz < MIN_FREQUENCY_GHZ || frequencyGhz > MAX_FREQUENCY_GHZ) {
            throw new InvalidSimulationParameterException(
                    "O modelo 3GPP TR 38.901 Rural Macro exige frequência entre 0,5 e 30 GHz. "
                            + "Frequência informada: " + frequencyGhz + " GHz.");
        }

        double distanceM = input.distanceM();
        if (distanceM <= 0) {
            throw new PropagationCalculationException(
                    "A distância deve ser maior que zero para o cálculo de propagação.");
        }
        if (distanceM < MIN_DISTANCE_M || distanceM > MAX_DISTANCE_M) {
            throw new InvalidSimulationParameterException(
                    "O modelo 3GPP TR 38.901 Rural Macro exige distância entre 10 m e 10 km. "
                            + "Distância informada: " + distanceM + " m.");
        }

        double buildingHeight = AVERAGE_BUILDING_HEIGHT_M;
        double heightPower = Math.pow(buildingHeight, 1.72);

        double firstTerm = 20 * Math.log10(40 * Math.PI * distanceM * frequencyGhz / 3.0);
        double distanceTerm = Math.min(0.03 * heightPower, 10.0) * Math.log10(distanceM);
        double heightCorrection = Math.min(0.044 * heightPower, 14.77);
        double terrainTerm = 0.002 * Math.log10(buildingHeight) * distanceM;

        return firstTerm + distanceTerm - heightCorrection + terrainTerm;
    }
}
