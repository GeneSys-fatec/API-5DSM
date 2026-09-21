package com.backend.tecsys.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RfParameter {
    public static final double DEFAULT_FREQUENCY_MHZ = 915.0;
    public static final double DEFAULT_TRANSMIT_POWER_DBM = 21.0;
    public static final double DEFAULT_RECEIVER_SENSITIVITY_DBM = -120.0;
    public static final double DEFAULT_ANTENNA_HEIGHT_M = 6.0;
    public static final double DEFAULT_DEVICE_HEIGHT_M = 5.0;
    public static final double DEFAULT_ANTENNA_GAIN_DBI = 0.0;
    public static final double DEFAULT_SYSTEM_LOSS_DB = 0.0;

    private double frequencyMhz;
    private double transmitPowerDbm;
    private double receiverSensitivityDbm;
    private double antennaHeightM;
    private double deviceHeightM;
    private double antennaGainDbi;
    private double systemLossDb;

    public static RfParameter defaults() {
        return RfParameter.builder()
                .frequencyMhz(DEFAULT_FREQUENCY_MHZ)
                .transmitPowerDbm(DEFAULT_TRANSMIT_POWER_DBM)
                .receiverSensitivityDbm(DEFAULT_RECEIVER_SENSITIVITY_DBM)
                .antennaHeightM(DEFAULT_ANTENNA_HEIGHT_M)
                .deviceHeightM(DEFAULT_DEVICE_HEIGHT_M)
                .antennaGainDbi(DEFAULT_ANTENNA_GAIN_DBI)
                .systemLossDb(DEFAULT_SYSTEM_LOSS_DB)
                .build();
    }
}
