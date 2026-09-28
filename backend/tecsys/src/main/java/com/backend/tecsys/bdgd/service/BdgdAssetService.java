package com.backend.tecsys.bdgd.service;

import com.backend.tecsys.bdgd.model.BdgdGeoJsonResponse;
import com.backend.tecsys.bdgd.repository.BdgdAssetRepository;
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
            Integer offset,
            Double minLon,
            Double minLat,
            Double maxLon,
            Double maxLat) {
        String normalizedLayer = layer == null ? "" : layer.trim().toUpperCase();
        String tableName = TABLES.get(normalizedLayer);
        if (tableName == null) {
            throw new IllegalArgumentException("Layer invalida. Use: " + String.join(", ", TABLES.keySet()));
        }

        int safeLimit = limit == null ? DEFAULT_LIMIT : Math.min(Math.max(limit, 1), MAX_LIMIT);
        int safeOffset = offset == null ? 0 : Math.max(offset, 0);
        if ((minLon != null || minLat != null || maxLon != null || maxLat != null)
            && (minLon == null || minLat == null || maxLon == null || maxLat == null)) {
            throw new IllegalArgumentException("Informe os quatro valores da bbox: minLon, minLat, maxLon e maxLat.");
        }
        if (minLon != null && (minLon >= maxLon || minLat >= maxLat)) {
            throw new IllegalArgumentException("bbox invalida: os valores minimos devem ser menores que os maximos.");
        }
        List<BdgdGeoJsonResponse.BdgdGeoJsonFeature> features = repository
            .findFeatures(tableName, blankToNull(distribuidora), blankToNull(regiao),
                minLon, minLat, maxLon, maxLat, safeLimit, safeOffset)
                .stream()
                .map(this::toFeature)
                .toList();

        return new BdgdGeoJsonResponse("FeatureCollection", features);
    }

    private BdgdGeoJsonResponse.BdgdGeoJsonFeature toFeature(Map<String, Object> row) {
        Object geometry;
        try {
            String geometryJson = (String) row.remove("geometry");
            geometry = objectMapper.readValue(geometryJson, Object.class);
        } catch (Exception exception) {
            throw new IllegalStateException("Geometria GeoJSON invalida", exception);
        }
        return new BdgdGeoJsonResponse.BdgdGeoJsonFeature("Feature", geometry, row);
    }

    public int countAssetsByDistribuidora(String distribuidora) {
        return repository.countAssetsByDistribuidora(distribuidora, List.copyOf(TABLES.values()));
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
