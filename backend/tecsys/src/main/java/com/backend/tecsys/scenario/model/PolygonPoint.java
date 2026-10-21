package com.backend.tecsys.scenario.model;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record PolygonPoint(
        @NotNull(message = "A latitude do ponto do polígono é obrigatória")
        @Min(value = -90, message = "A latitude deve ser no mínimo -90")
        @Max(value = 90, message = "A latitude deve ser no máximo 90")
        Double latitude,

        @NotNull(message = "A longitude do ponto do polígono é obrigatória")
        @Min(value = -180, message = "A longitude deve ser no mínimo -180")
        @Max(value = 180, message = "A longitude deve ser no máximo 180")
        Double longitude) {
}
