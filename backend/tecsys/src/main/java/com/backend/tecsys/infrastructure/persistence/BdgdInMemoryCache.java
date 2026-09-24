package com.backend.tecsys.infrastructure.persistence;

import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.scenario.model.Asset;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

@Component
public class BdgdInMemoryCache {

    private final List<Asset> assets = new ArrayList<>();
    
    private Double minLat = -90.0;
    private Double maxLat = 90.0;
    private Double minLon = -180.0;
    private Double maxLon = 180.0;

    public BdgdInMemoryCache() {
        assets.add(Asset.builder().assetKey("1").assetType("POSTE").coordinate(new RfCoordinate(-23.550520, -46.633308)).build());
        assets.add(Asset.builder().assetKey("2").assetType("POSTE").coordinate(new RfCoordinate(-23.551000, -46.634000)).build());
        assets.add(Asset.builder().assetKey("3").assetType("SUBESTACAO").coordinate(new RfCoordinate(-23.552000, -46.635000)).build());
        
        this.minLat = -25.0;
        this.maxLat = -20.0;
        this.minLon = -53.0;
        this.maxLon = -44.0;
    }

    public List<Asset> getAllAssets() {
        return new ArrayList<>(assets);
    }

    public void addAsset(Asset asset) {
        assets.add(asset);
    }
    
    public void setRegionBounds(Double minLat, Double maxLat, Double minLon, Double maxLon) {
        this.minLat = minLat;
        this.maxLat = maxLat;
        this.minLon = minLon;
        this.maxLon = maxLon;
    }

    public boolean isPointInRegion(Double latitude, Double longitude) {
        return latitude >= minLat && latitude <= maxLat &&
               longitude >= minLon && longitude <= maxLon;
    }
}
