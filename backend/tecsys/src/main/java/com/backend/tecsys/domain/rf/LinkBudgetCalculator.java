package com.backend.tecsys.domain.rf;

import com.backend.tecsys.domain.model.RfParameter;
import org.springframework.stereotype.Component;

@Component
public class LinkBudgetCalculator {

    public double receivedPowerDbm(RfParameter rfParameter, double propagationLossDb) {
        return rfParameter.getTransmitPowerDbm()
                + rfParameter.getAntennaGainDbi()
                - rfParameter.getSystemLossDb()
                - propagationLossDb;
    }

    public boolean isCovered(double receivedPowerDbm, RfParameter rfParameter) {
        return receivedPowerDbm >= rfParameter.getReceiverSensitivityDbm();
    }
}
