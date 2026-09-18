package com.backend.tecsys.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Asset {
    private String assetKey;
    private String assetType;
    private Long utilityId;
    private RfCoordinate coordinate;
}
