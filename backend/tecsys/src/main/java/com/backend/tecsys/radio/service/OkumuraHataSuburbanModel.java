package com.backend.tecsys.radio.service;import com.backend.tecsys.radio.model.PropagationInput;


import com.backend.tecsys.scenario.exception.InvalidSimulationParameterException;
import com.backend.tecsys.radio.exception.PropagationCalculationException;
import com.backend.tecsys.scenario.model.PropagationModelType;
import org.springframework.stereotype.Component;

@Component
public class OkumuraHataSuburbanModel implements PropagationModel {

    private static final double MIN_FREQUENCY_MHZ = 150.0;
    private static final double MAX_FREQUENCY_MHZ = 1500.0;

    @Override
    public PropagationModelType type() {
        return PropagationModelType.OKUMURA_HATA_SUBURBAN;
    }

    @Override
    public double calculatePropagationLossDb(PropagationInput input) {
        double frequencyMhz = input.frequencyMhz();
        if (frequencyMhz < MIN_FREQUENCY_MHZ || frequencyMhz > MAX_FREQUENCY_MHZ) {
            throw new InvalidSimulationParameterException(
                    "O modelo Okumura-Hata Suburban exige frequência entre 150 e 1500 MHz. "
                            + "Frequência informada: " + frequencyMhz + " MHz.");
        }

        double distanceKm = input.distanceKm();
        if (distanceKm <= 0) {
            throw new PropagationCalculationException(
                    "A distância deve ser maior que zero para o cálculo de propagação.");
        }

        double gatewayHeight = input.gatewayHeightM();
        double deviceHeight = input.deviceHeightM();

        double deviceHeightCorrection =
                (1.1 * Math.log10(frequencyMhz) - 0.7) * deviceHeight
                        - (1.56 * Math.log10(frequencyMhz) - 0.8);

        double urbanLoss =
                69.55
                        + 26.16 * Math.log10(frequencyMhz)
                        - 13.82 * Math.log10(gatewayHeight)
                        - deviceHeightCorrection
                        + (44.9 - 6.55 * Math.log10(gatewayHeight)) * Math.log10(distanceKm);

        double suburbanCorrection =
                2 * Math.pow(Math.log10(frequencyMhz / 28.0), 2) + 5.4;

        return urbanLoss - suburbanCorrection;
    }
}
