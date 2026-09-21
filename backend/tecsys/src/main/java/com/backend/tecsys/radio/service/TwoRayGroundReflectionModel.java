package com.backend.tecsys.radio.service;

import com.backend.tecsys.radio.exception.PropagationCalculationException;
import com.backend.tecsys.radio.model.PropagationInput;
import com.backend.tecsys.scenario.exception.InvalidSimulationParameterException;
import com.backend.tecsys.scenario.model.PropagationModelType;
import org.springframework.stereotype.Component;

@Component
public class TwoRayGroundReflectionModel implements PropagationModel {

    private static final double SPEED_OF_LIGHT_M_S = 299792458.0;

    @Override
    public PropagationModelType type() {
        return PropagationModelType.TWO_RAY_GROUND;
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

        double gatewayHeight = input.gatewayHeightM();
        if (gatewayHeight <= 0) {
            throw new InvalidSimulationParameterException(
                    "A altura do gateway deve ser maior que zero. Informada: " + gatewayHeight + " m.");
        }

        double deviceHeight = input.deviceHeightM();
        if (deviceHeight <= 0) {
            throw new InvalidSimulationParameterException(
                    "A altura do dispositivo deve ser maior que zero. Informada: " + deviceHeight + " m.");
        }

        double wavelengthM = SPEED_OF_LIGHT_M_S / (frequencyMhz * 1_000_000.0);
        double breakpointDistanceM = (4.0 * Math.PI * gatewayHeight * deviceHeight) / wavelengthM;

        if (distanceM <= breakpointDistanceM) {
            return 20.0 * Math.log10(distanceM) + 20.0 * Math.log10(frequencyMhz) - 27.55;
        }

        return 40.0 * Math.log10(distanceM)
                - 20.0 * Math.log10(gatewayHeight)
                - 20.0 * Math.log10(deviceHeight);
    }

    public double calculateBreakpointDistanceM(double frequencyMhz, double gatewayHeightM, double deviceHeightM) {
        double wavelengthM = SPEED_OF_LIGHT_M_S / (frequencyMhz * 1_000_000.0);
        return (4.0 * Math.PI * gatewayHeightM * deviceHeightM) / wavelengthM;
    }
}
