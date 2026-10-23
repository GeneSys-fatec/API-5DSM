package com.backend.tecsys.scenario.dto;

import com.backend.tecsys.scenario.model.PolygonPoint;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SearchAreaRequest {

    @NotNull(message = "O identificador da importacao BDGD e obrigatorio")
    private UUID importId;

    @NotNull(message = "A latitude do ponto central é obrigatória")
    @Min(value = -90, message = "A latitude deve ser no mínimo -90")
    @Max(value = 90, message = "A latitude deve ser no máximo 90")
    private Double latitude;

    @NotNull(message = "A longitude do ponto central é obrigatória")
    @Min(value = -180, message = "A longitude deve ser no mínimo -180")
    @Max(value = 180, message = "A longitude deve ser no máximo 180")
    private Double longitude;

    private Double radius;

    @Size(min = 3, message = "O polígono manual deve ter no mínimo 3 pontos")
    @Valid
    private List<PolygonPoint> polygonPoints;

    public boolean hasPolygon() {
        return polygonPoints != null && !polygonPoints.isEmpty();
    }
}
