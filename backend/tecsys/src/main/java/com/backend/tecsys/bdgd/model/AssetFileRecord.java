package com.backend.tecsys.bdgd.model;

public record AssetFileRecord(
        int rowNumber,
        String assetKey,
        String assetType,
        Double latitude,
        Double longitude,
        String distribuidora,
        String regiao
) {
}
