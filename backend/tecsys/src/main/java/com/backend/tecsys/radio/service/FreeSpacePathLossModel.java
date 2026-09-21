package com.backend.tecsys.radio.service;

import com.backend.tecsys.radio.exception.PropagationCalculationException;
import com.backend.tecsys.radio.model.PropagationInput;
import com.backend.tecsys.scenario.exception.InvalidSimulationParameterException;
import com.backend.tecsys.scenario.model.PropagationModelType;
import org.springframework.stereotype.Component;

@Component
public class FreeSpacePathLossModel implements PropagationModel {

    @Override
    public PropagationModelType type() {
        return PropagationModelType.FREE_SPACE;
    }

    @Override
    public double calculatePropagationLossDb(PropagationInput input) {
        double frequencyMhz = input.frequencyMhz();
        if (frequencyMhz <= 0) {
            throw new InvalidSimulationParameterException(
                    "A frequência deve ser maior que zero. Informada: " + frequencyMhz + " MHz.");
        }

        double distanceM = input.distanceM();
        if (distanceM <= 0) {
            throw new PropagationCalculationException(
                    "A distância deve ser maior que zero para o cálculo de propagação.");
        }

        return 20.0 * Math.log10(distanceM) + 20.0 * Math.log10(frequencyMhz) - 27.55;
    }
}
