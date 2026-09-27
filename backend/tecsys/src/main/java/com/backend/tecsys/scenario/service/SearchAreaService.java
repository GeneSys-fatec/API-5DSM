package com.backend.tecsys.scenario.service;

import com.backend.tecsys.infrastructure.persistence.BdgdInMemoryCache;
import com.backend.tecsys.scenario.dto.AssetDto;
import com.backend.tecsys.scenario.dto.SearchAreaRequest;
import com.backend.tecsys.scenario.dto.SearchAreaResponse;
import com.backend.tecsys.scenario.model.Asset;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class SearchAreaService {

    private final BdgdInMemoryCache bdgdCache;
    private final com.backend.tecsys.scenario.repository.IAssetRepository assetRepository;

    @Value("${search.area.radius.min:100.0}")
    private Double minRadius;

    @Value("${search.area.radius.max:8000.0}")
    private Double maxRadius;

    private static final double EARTH_RADIUS = 6371e3;

    public SearchAreaService(
            BdgdInMemoryCache bdgdCache,
            com.backend.tecsys.scenario.repository.IAssetRepository assetRepository) {
        this.bdgdCache = bdgdCache;
        this.assetRepository = assetRepository;
    }

    public SearchAreaResponse processSearchArea(SearchAreaRequest request) {
        if (request.getRadius() < minRadius || request.getRadius() > maxRadius) {
            throw new IllegalArgumentException("O raio informado (" + request.getRadius() + 
                    "m) deve estar entre " + minRadius + "m e " + maxRadius + "m.");
        }

        List<AssetDto> candidates = new java.util.ArrayList<>();
        try {
            List<Asset> dbAssets = assetRepository.findWithinRadius(
                    request.getLatitude(), request.getLongitude(), request.getRadius());
            if (dbAssets != null && !dbAssets.isEmpty()) {
                candidates = dbAssets.stream().map(this::mapToDto).collect(Collectors.toList());
            }
        } catch (Exception ignored) {
        }

        if (candidates.isEmpty()) {
            List<Asset> allAssets = bdgdCache.getAllAssets();
            candidates = allAssets.stream()
                    .filter(asset -> calculateHaversineDistance(request.getLatitude(), request.getLongitude(),
                            asset.getCoordinate().latitude(), asset.getCoordinate().longitude()) <= request.getRadius())
                    .map(this::mapToDto)
                    .collect(Collectors.toList());
        }

        String validationStatus = "OK";
        String message = "Área delimitada com sucesso.";

        if (candidates.isEmpty()) {
            double latOffset = (request.getRadius() / EARTH_RADIUS) * (180 / Math.PI);
            double lonOffset = (request.getRadius() / EARTH_RADIUS) * (180 / Math.PI) / Math.cos(request.getLatitude() * Math.PI / 180);

            boolean insideBounds = bdgdCache.isPointInRegion(request.getLatitude(), request.getLongitude()) &&
                    bdgdCache.isPointInRegion(request.getLatitude() + latOffset, request.getLongitude()) &&
                    bdgdCache.isPointInRegion(request.getLatitude() - latOffset, request.getLongitude()) &&
                    bdgdCache.isPointInRegion(request.getLatitude(), request.getLongitude() + lonOffset) &&
                    bdgdCache.isPointInRegion(request.getLatitude(), request.getLongitude() - lonOffset);

            if (!insideBounds) {
                validationStatus = "WARNING_OUT_OF_BOUNDS";
                message = "A área definida ultrapassa a região coberta pela BDGD importada.";
            }
        } else {
            message = "Área delimitada com sucesso (" + candidates.size() + " ativos encontrados na base BDGD).";
        }

        return SearchAreaResponse.builder()
                .candidates(candidates)
                .validationStatus(validationStatus)
                .message(message)
                .build();
    }

    private double calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);

        lat1 = Math.toRadians(lat1);
        lat2 = Math.toRadians(lat2);

        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                   Math.sin(dLon / 2) * Math.sin(dLon / 2) * Math.cos(lat1) * Math.cos(lat2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return EARTH_RADIUS * c;
    }

    private AssetDto mapToDto(Asset asset) {
        return AssetDto.builder()
                .id(asset.getAssetKey())
                .type(asset.getAssetType())
                .latitude(asset.getCoordinate().latitude())
                .longitude(asset.getCoordinate().longitude())
                .build();
    }
}
