package com.backend.tecsys.scenario.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AssetDto {
    private String id;
    private String type;
    private Double latitude;
    private Double longitude;
}
