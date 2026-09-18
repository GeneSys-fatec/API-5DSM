package com.backend.tecsys.bdgd.model;

import com.fasterxml.jackson.databind.JsonNode;

import java.util.List;
import java.util.Map;

public record BdgdGeoJsonResponse(
        String type,
        List<BdgdGeoJsonFeature> features) {

    public record BdgdGeoJsonFeature(
            String type,
            JsonNode geometry,
            Map<String, Object> properties) {
    }
}
