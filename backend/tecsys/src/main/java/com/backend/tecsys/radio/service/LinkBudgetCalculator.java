package com.backend.tecsys.radio.service;

import com.backend.tecsys.radio.model.RfParameter;
import org.springframework.stereotype.Component;

@Component
public class LinkBudgetCalculator {

    public double receivedPowerDbm(RfParameter rfParameter, double propagationLossDb) {
        return rfParameter.getTransmitPowerDbm()
                + rfParameter.getAntennaGainDbi()
                - rfParameter.getSystemLossDb()
                - propagationLossDb;
    }

    public double maxPermissiblePathLossDb(RfParameter rfParameter) {
        return rfParameter.getTransmitPowerDbm()
                + rfParameter.getAntennaGainDbi()
                - rfParameter.getSystemLossDb()
                - rfParameter.getReceiverSensitivityDbm();
    }

    public double linkMarginDb(double receivedPowerDbm, RfParameter rfParameter) {
        return receivedPowerDbm - rfParameter.getReceiverSensitivityDbm();
    }

    public boolean isCovered(double receivedPowerDbm, RfParameter rfParameter) {
        return receivedPowerDbm >= rfParameter.getReceiverSensitivityDbm();
    }

    public boolean isPathLossCovered(double propagationLossDb, RfParameter rfParameter) {
        return propagationLossDb <= maxPermissiblePathLossDb(rfParameter);
    }
}
