package com.backend.tecsys.bdgd.service;

import com.backend.tecsys.bdgd.model.BdgdGeoJsonResponse;
import com.backend.tecsys.bdgd.repository.BdgdAssetRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class BdgdAssetService {
    private static final Map<String, String> TABLES = Map.of(
            "POSTE", "poste",
            "SUB", "sub",
            "UCBT", "ucbt",
            "UCMT", "ucmt",
            "SSDBT", "ssdbt",
            "SSDMT", "ssdmt",
            "SSDAT", "ssdat"
    );
    private static final int DEFAULT_LIMIT = 1000;
    private static final int MAX_LIMIT = 10000;

    private final BdgdAssetRepository repository;
    private final ObjectMapper objectMapper;

    public BdgdGeoJsonResponse findFeatures(
            String layer,
            String distribuidora,
            String regiao,
            Integer limit,
            Integer offset) {
        String normalizedLayer = layer == null ? "" : layer.trim().toUpperCase();
        String tableName = TABLES.get(normalizedLayer);
        if (tableName == null) {
            throw new IllegalArgumentException("Layer invalida. Use: " + String.join(", ", TABLES.keySet()));
        }

        int safeLimit = limit == null ? DEFAULT_LIMIT : Math.min(Math.max(limit, 1), MAX_LIMIT);
        int safeOffset = offset == null ? 0 : Math.max(offset, 0);
        List<BdgdGeoJsonResponse.BdgdGeoJsonFeature> features = repository
                .findFeatures(tableName, blankToNull(distribuidora), blankToNull(regiao), safeLimit, safeOffset)
                .stream()
                .map(this::toFeature)
                .toList();

        return new BdgdGeoJsonResponse("FeatureCollection", features);
    }

    private BdgdGeoJsonResponse.BdgdGeoJsonFeature toFeature(Map<String, Object> row) {
        JsonNode geometry;
        try {
            geometry = objectMapper.readTree((String) row.remove("geometry"));
        } catch (Exception exception) {
            throw new IllegalStateException("Geometria GeoJSON invalida", exception);
        }
        return new BdgdGeoJsonResponse.BdgdGeoJsonFeature("Feature", geometry, row);
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
