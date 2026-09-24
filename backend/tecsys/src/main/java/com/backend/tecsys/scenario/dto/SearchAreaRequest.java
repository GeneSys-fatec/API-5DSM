package com.backend.tecsys.scenario.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SearchAreaRequest {

    @NotNull(message = "A latitude do ponto central é obrigatória")
    @Min(value = -90, message = "A latitude deve ser no mínimo -90")
    @Max(value = 90, message = "A latitude deve ser no máximo 90")
    private Double latitude;

    @NotNull(message = "A longitude do ponto central é obrigatória")
    @Min(value = -180, message = "A longitude deve ser no mínimo -180")
    @Max(value = 180, message = "A longitude deve ser no máximo 180")
    private Double longitude;

    @NotNull(message = "O raio de atuação é obrigatório")
    private Double radius;
}
