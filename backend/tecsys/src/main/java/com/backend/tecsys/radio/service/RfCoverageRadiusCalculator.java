package com.backend.tecsys.radio.service;

import com.backend.tecsys.radio.model.PropagationInput;
import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.radio.model.RfParameter;
import com.backend.tecsys.radio.model.TerrainProfile;
import com.backend.tecsys.scenario.exception.InvalidSimulationParameterException;
import com.backend.tecsys.scenario.model.PropagationModelType;
import org.springframework.stereotype.Service;

@Service
public class RfCoverageRadiusCalculator {

    private static final double MIN_RADIUS_METERS = 1.0;
    private static final double MAX_RADIUS_METERS = 100_000.0;
    private static final double SPEED_OF_LIGHT_M_S = 299792458.0;

    private final LinkBudgetCalculator linkBudgetCalculator;

    public RfCoverageRadiusCalculator(LinkBudgetCalculator linkBudgetCalculator) {
        this.linkBudgetCalculator = linkBudgetCalculator;
    }

    public CoverageRadiusResult calculateCoverageRadius(RfParameter rfParameter, PropagationModel propagationModel) {
        validateRfParameter(rfParameter);

        double maxPathLossDb = linkBudgetCalculator.maxPermissiblePathLossDb(rfParameter);
        if (maxPathLossDb <= 0) {
            throw new InvalidSimulationParameterException(
                    "O Link Budget resultou em perda máxima permitida não positiva ("
                            + maxPathLossDb + " dB). Verifique a potência de transmissão e a sensibilidade.");
        }

        PropagationModelType type = propagationModel.type();
        double radiusMeters;
        double breakpointDistanceMeters = 0.0;

        switch (type) {
            case FREE_SPACE:
                radiusMeters = calculateFreeSpaceRadiusMeters(rfParameter.getFrequencyMhz(), maxPathLossDb);
                break;
            case TWO_RAY_GROUND:
                double wavelengthM = SPEED_OF_LIGHT_M_S / (rfParameter.getFrequencyMhz() * 1_000_000.0);
                breakpointDistanceMeters = (4.0 * Math.PI * rfParameter.getAntennaHeightM() * rfParameter.getDeviceHeightM()) / wavelengthM;
                radiusMeters = calculateTwoRayRadiusMeters(rfParameter, maxPathLossDb, breakpointDistanceMeters);
                break;
            case OKUMURA_HATA_SUBURBAN:
                radiusMeters = calculateOkumuraHataSuburbanRadiusMeters(rfParameter, maxPathLossDb);
                break;
            default:
                radiusMeters = calculateByBinarySearch(rfParameter, propagationModel, maxPathLossDb);
                break;
        }

        radiusMeters = Math.max(MIN_RADIUS_METERS, Math.min(radiusMeters, MAX_RADIUS_METERS));

        return new CoverageRadiusResult(radiusMeters, maxPathLossDb, type, breakpointDistanceMeters);
    }

    public double calculateRadiusMeters(RfParameter rfParameter, PropagationModel propagationModel) {
        return calculateCoverageRadius(rfParameter, propagationModel).radiusMeters();
    }

    private double calculateFreeSpaceRadiusMeters(double frequencyMhz, double maxPathLossDb) {
        double exponent = (maxPathLossDb - 20.0 * Math.log10(frequencyMhz) + 27.55) / 20.0;
        return Math.pow(10.0, exponent);
    }

    private double calculateTwoRayRadiusMeters(RfParameter rfParameter, double maxPathLossDb, double breakpointDistanceM) {
        double frequencyMhz = rfParameter.getFrequencyMhz();
        double fsplAtBreakpoint = 20.0 * Math.log10(breakpointDistanceM) + 20.0 * Math.log10(frequencyMhz) - 27.55;

        if (maxPathLossDb <= fsplAtBreakpoint) {
            return calculateFreeSpaceRadiusMeters(frequencyMhz, maxPathLossDb);
        }

        double gatewayHeightM = rfParameter.getAntennaHeightM();
        double deviceHeightM = rfParameter.getDeviceHeightM();
        double exponent = (maxPathLossDb + 20.0 * Math.log10(gatewayHeightM) + 20.0 * Math.log10(deviceHeightM)) / 40.0;
        return Math.pow(10.0, exponent);
    }

    private double calculateOkumuraHataSuburbanRadiusMeters(RfParameter rfParameter, double maxPathLossDb) {
        double frequencyMhz = rfParameter.getFrequencyMhz();
        double gatewayHeightM = rfParameter.getAntennaHeightM();
        double deviceHeightM = rfParameter.getDeviceHeightM();

        double deviceHeightCorrection =
                (1.1 * Math.log10(frequencyMhz) - 0.7) * deviceHeightM
                        - (1.56 * Math.log10(frequencyMhz) - 0.8);

        double baseLoss = 69.55
                + 26.16 * Math.log10(frequencyMhz)
                - 13.82 * Math.log10(gatewayHeightM)
                - deviceHeightCorrection;

        double suburbanCorrection = 2.0 * Math.pow(Math.log10(frequencyMhz / 28.0), 2) + 5.4;
        double slope = 44.9 - 6.55 * Math.log10(gatewayHeightM);

        double targetLoss = maxPathLossDb + suburbanCorrection - baseLoss;
        double logDistanceKm = targetLoss / slope;
        double distanceKm = Math.pow(10.0, logDistanceKm);

        return distanceKm * 1000.0;
    }

    private double calculateByBinarySearch(RfParameter rfParameter, PropagationModel propagationModel, double maxPathLossDb) {
        double lowM = MIN_RADIUS_METERS;
        double highM = MAX_RADIUS_METERS;
        if (propagationModel.type() == PropagationModelType.THREE_GPP_RURAL_MACRO) {
            lowM = 10.0;
            highM = 10_000.0;
        }
        RfCoordinate origin = new RfCoordinate(0.0, 0.0);

        for (int i = 0; i < 35; i++) {
            double midM = (lowM + highM) / 2.0;
            RfCoordinate destination = new RfCoordinate(0.0, midM / 111_000.0);
            PropagationInput input = new PropagationInput(
                    rfParameter.getFrequencyMhz(),
                    origin,
                    destination,
                    midM,
                    rfParameter.getAntennaHeightM(),
                    rfParameter.getDeviceHeightM(),
                    TerrainProfile.empty());

            double lossDb;
            try {
                lossDb = propagationModel.calculatePropagationLossDb(input);
            } catch (InvalidSimulationParameterException e) {
                highM = midM;
                continue;
            }

            if (lossDb > maxPathLossDb) {
                highM = midM;
            } else {
                lowM = midM;
            }
        }

        return (lowM + highM) / 2.0;
    }

    private void validateRfParameter(RfParameter rfParameter) {
        if (rfParameter == null) {
            throw new InvalidSimulationParameterException("Os parâmetros de RF são obrigatórios.");
        }
        if (rfParameter.getFrequencyMhz() <= 0) {
            throw new InvalidSimulationParameterException("Frequência deve ser maior que zero.");
        }
        if (rfParameter.getAntennaHeightM() <= 0) {
            throw new InvalidSimulationParameterException("Altura do gateway deve ser maior que zero.");
        }
        if (rfParameter.getDeviceHeightM() <= 0) {
            throw new InvalidSimulationParameterException("Altura do dispositivo deve ser maior que zero.");
        }
        if (rfParameter.getReceiverSensitivityDbm() >= rfParameter.getTransmitPowerDbm()) {
            throw new InvalidSimulationParameterException(
                    "A sensibilidade do receptor (" + rfParameter.getReceiverSensitivityDbm()
                            + " dBm) não pode ser maior ou igual à potência de transmissão ("
                            + rfParameter.getTransmitPowerDbm() + " dBm).");
        }
    }

    public record CoverageRadiusResult(
            double radiusMeters,
            double maxPathLossDb,
            PropagationModelType modelType,
            double breakpointDistanceMeters
    ) {}
}
