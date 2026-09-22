package com.backend.tecsys.bdgd.model;

import java.util.List;
import java.util.Map;

public record BdgdGeoJsonResponse(
        String type,
        List<BdgdGeoJsonFeature> features) {

    public record BdgdGeoJsonFeature(
            String type,
            Object geometry,
            Map<String, Object> properties) {
    }
}
