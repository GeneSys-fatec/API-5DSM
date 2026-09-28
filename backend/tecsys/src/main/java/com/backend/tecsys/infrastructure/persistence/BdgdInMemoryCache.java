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

        assets.add(Asset.builder().assetKey("CAMP-SUB-1").assetType("SUBESTACAO").coordinate(new RfCoordinate(-22.9068, -47.0616)).build());
        assets.add(Asset.builder().assetKey("CAMP-REL-1").assetType("RELIGADOR").coordinate(new RfCoordinate(-22.9040, -47.0630)).build());
        assets.add(Asset.builder().assetKey("CAMP-REL-2").assetType("RELIGADOR").coordinate(new RfCoordinate(-22.9090, -47.0600)).build());
        assets.add(Asset.builder().assetKey("CAMP-TR-1").assetType("TRAFO").coordinate(new RfCoordinate(-22.9055, -47.0590)).build());
        assets.add(Asset.builder().assetKey("CAMP-TR-2").assetType("TRAFO").coordinate(new RfCoordinate(-22.9080, -47.0640)).build());
        assets.add(Asset.builder().assetKey("CAMP-POS-1").assetType("POSTE").coordinate(new RfCoordinate(-22.9060, -47.0610)).build());
        assets.add(Asset.builder().assetKey("CAMP-POS-2").assetType("POSTE").coordinate(new RfCoordinate(-22.9075, -47.0625)).build());
        assets.add(Asset.builder().assetKey("CAMP-POS-3").assetType("POSTE").coordinate(new RfCoordinate(-22.9050, -47.0635)).build());
        assets.add(Asset.builder().assetKey("CAMP-POS-4").assetType("POSTE").coordinate(new RfCoordinate(-22.9085, -47.0595)).build());
        
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
