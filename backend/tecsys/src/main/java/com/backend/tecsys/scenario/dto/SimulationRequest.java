package com.backend.tecsys.scenario.dto;

import com.backend.tecsys.radio.model.RfParameter;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Negative;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "Parâmetros de entrada da simulação de cobertura de ativos.")
public class SimulationRequest {

    @NotBlank(message = "O nome do cenário é obrigatório.")
    @Schema(description = "Nome do cenário de simulação.", example = "Cenário Centro")
    private String name;

    @Schema(description = "Nome da região/área do cenário.", example = "Centro")
    private String regionName;

    @NotNull(message = "A meta de cobertura é obrigatória.")
    @DecimalMin(value = "1.0", message = "A meta de cobertura deve ser no mínimo 1%.")
    @DecimalMax(value = "100.0", message = "A meta de cobertura deve ser no máximo 100%.")
    @Schema(description = "Meta de cobertura em percentual (1 a 100).", example = "90")
    private Double coverageTargetPct;

    @NotNull(message = "A quantidade máxima de gateways é obrigatória.")
    @Min(value = 1, message = "A quantidade máxima de gateways deve ser maior ou igual a 1.")
    @Schema(description = "Quantidade máxima de gateways a selecionar.", example = "5")
    private Integer maxGateways;

    @NotBlank(message = "O modelo de propagação é obrigatório.")
    @Schema(description = "Modelo de propagação RF.",
            example = "OKUMURA_HATA_SUBURBAN",
            allowableValues = {"OKUMURA_HATA_SUBURBAN", "THREE_GPP_RURAL_MACRO", "ITM_LONGLEY_RICE"})
    private String propagationModel;

    @PositiveOrZero(message = "O custo unitário do gateway não pode ser negativo.")
    @Schema(description = "Custo unitário do gateway. Quando omitido, usa o valor padrão do mock.", example = "1500")
    private Double gatewayUnitCost;

    @Positive(message = "A frequência deve ser maior que zero.")
    @Schema(description = "Frequência em MHz. Padrão: 915.", example = "915")
    private Double frequencyMhz;

    @Positive(message = "A potência de transmissão deve ser maior que zero.")
    @Schema(description = "Potência de transmissão em dBm. Padrão: 21.", example = "21")
    private Double transmitPowerDbm;

    @Negative(message = "A sensibilidade do receptor deve ser menor que zero.")
    @Schema(description = "Sensibilidade do receptor em dBm. Padrão: -120.", example = "-120")
    private Double receiverSensitivityDbm;

    @Positive(message = "A altura do gateway deve ser maior que zero.")
    @Schema(description = "Altura da antena do gateway em metros. Padrão: 6.", example = "6")
    private Double antennaHeightM;

    @Positive(message = "A altura do dispositivo deve ser maior que zero.")
    @Schema(description = "Altura do dispositivo em metros. Padrão: 5.", example = "5")
    private Double deviceHeightM;

    @Schema(description = "Ganho da antena em dBi. Padrão: 0.", example = "0")
    private Double antennaGainDbi;

    @PositiveOrZero(message = "As perdas do sistema não podem ser negativas.")
    @Schema(description = "Perdas do sistema em dB. Padrão: 0.", example = "0")
    private Double systemLossDb;

    public RfParameter toRfParameter() {
        return RfParameter.builder()
                .frequencyMhz(frequencyMhz != null ? frequencyMhz : RfParameter.DEFAULT_FREQUENCY_MHZ)
                .transmitPowerDbm(transmitPowerDbm != null ? transmitPowerDbm : RfParameter.DEFAULT_TRANSMIT_POWER_DBM)
                .receiverSensitivityDbm(receiverSensitivityDbm != null
                        ? receiverSensitivityDbm
                        : RfParameter.DEFAULT_RECEIVER_SENSITIVITY_DBM)
                .antennaHeightM(antennaHeightM != null ? antennaHeightM : RfParameter.DEFAULT_ANTENNA_HEIGHT_M)
                .deviceHeightM(deviceHeightM != null ? deviceHeightM : RfParameter.DEFAULT_DEVICE_HEIGHT_M)
                .antennaGainDbi(antennaGainDbi != null ? antennaGainDbi : RfParameter.DEFAULT_ANTENNA_GAIN_DBI)
                .systemLossDb(systemLossDb != null ? systemLossDb : RfParameter.DEFAULT_SYSTEM_LOSS_DB)
                .build();
    }
}
