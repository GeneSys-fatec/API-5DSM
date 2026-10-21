package com.backend.tecsys.scenario.repository;

import com.backend.tecsys.scenario.model.Asset;
import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.scenario.repository.IAssetRepository;
import com.backend.tecsys.scenario.model.PolygonPoint;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Repository
@Profile("mock")
public class MockAssetRepository implements IAssetRepository {

    private static final double BASE_LATITUDE = -22.0000;
    private static final double BASE_LONGITUDE = -47.0000;
    private static final double CAMPINAS_LATITUDE = -22.9068;
    private static final double CAMPINAS_LONGITUDE = -47.0616;
    private static final double GRID_STEP_DEGREES = 0.0040;
    private static final int COLUMNS = 5;
    private static final int ASSET_COUNT = 20;
    private static final String[] ASSET_TYPES = {"POSTE", "UCBT", "UCMT", "SSDMT", "SUB"};

    @Override
    public List<Asset> findByImportId(UUID importId) {
        List<Asset> assets = new ArrayList<>();

        for (int index = 0; index < ASSET_COUNT; index++) {
            int row = index / COLUMNS;
            int column = index % COLUMNS;

            double latitude = BASE_LATITUDE + row * GRID_STEP_DEGREES;
            double longitude = BASE_LONGITUDE + column * GRID_STEP_DEGREES;

            assets.add(Asset.builder()
                    .assetKey("ASSET-" + (index + 1))
                    .assetType(ASSET_TYPES[index % ASSET_TYPES.length])
                    .coordinate(new RfCoordinate(latitude, longitude))
                    .build());
        }

        for (int index = 0; index < ASSET_COUNT; index++) {
            int row = index / COLUMNS;
            int column = index % COLUMNS;

            double latitude = CAMPINAS_LATITUDE + (row - 2) * GRID_STEP_DEGREES;
            double longitude = CAMPINAS_LONGITUDE + (column - 2) * GRID_STEP_DEGREES;

            assets.add(Asset.builder()
                    .assetKey("ASSET-CAMPINAS-" + (index + 1))
                    .assetType(ASSET_TYPES[index % ASSET_TYPES.length])
                    .coordinate(new RfCoordinate(latitude, longitude))
                    .build());
        }

        return assets;
    }

    @Override
    public List<Asset> findWithinRadius(UUID importId, double latitude, double longitude, double radiusMeters) {
        List<Asset> all = findByImportId(importId);
        List<Asset> result = new ArrayList<>();
        for (Asset a : all) {
            double dLat = Math.toRadians(a.getCoordinate().latitude() - latitude);
            double dLon = Math.toRadians(a.getCoordinate().longitude() - longitude);
            double sinLat = Math.sin(dLat / 2);
            double sinLon = Math.sin(dLon / 2);
            double h = sinLat * sinLat + Math.cos(Math.toRadians(latitude)) * Math.cos(Math.toRadians(a.getCoordinate().latitude())) * sinLon * sinLon;
            double dist = 6371000.0 * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
            if (dist <= radiusMeters) {
                result.add(a);
            }
        }
        return result;
    }

    @Override
    public List<Asset> findAllWithinRadius(UUID importId, double latitude, double longitude, double radiusMeters) {
        return findWithinRadius(importId, latitude, longitude, radiusMeters);
    }

    @Override
    public List<Asset> findWithinPolygon(UUID importId, List<PolygonPoint> polygonPoints) {
        List<Asset> all = findByImportId(importId);
        List<Asset> result = new ArrayList<>();
        for (Asset a : all) {
            if (isPointInsidePolygon(a.getCoordinate().latitude(), a.getCoordinate().longitude(), polygonPoints)) {
                result.add(a);
            }
        }
        return result;
    }

    private boolean isPointInsidePolygon(double latitude, double longitude, List<PolygonPoint> polygon) {
        boolean inside = false;
        int vertexCount = polygon.size();
        for (int i = 0, j = vertexCount - 1; i < vertexCount; j = i++) {
            double latI = polygon.get(i).latitude();
            double lonI = polygon.get(i).longitude();
            double latJ = polygon.get(j).latitude();
            double lonJ = polygon.get(j).longitude();

            boolean intersects = (lonI > longitude) != (lonJ > longitude)
                    && (latitude < (latJ - latI) * (longitude - lonI) / (lonJ - lonI) + latI);
            if (intersects) {
                inside = !inside;
            }
        }
        return inside;
    }
}
