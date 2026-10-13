package com.backend.tecsys.infrastructure.persistence;

import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.scenario.model.Asset;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class BdgdInMemoryCache {

    private static final int MAX_CACHE_SIZE = 50_000;

    private final Map<String, Asset> assetsByKey = Collections.synchronizedMap(
            new LinkedHashMap<String, Asset>(1000, 0.75f, true) {
                @Override
                protected boolean removeEldestEntry(Map.Entry<String, Asset> eldest) {
                    return size() > MAX_CACHE_SIZE;
                }
            }
    );
    
    private Double minLat = -90.0;
    private Double maxLat = 90.0;
    private Double minLon = -180.0;
    private Double maxLon = 180.0;

    public BdgdInMemoryCache() {
        addAsset(Asset.builder().assetKey("1").assetType("POSTE").coordinate(new RfCoordinate(-23.550520, -46.633308)).build());
        addAsset(Asset.builder().assetKey("2").assetType("POSTE").coordinate(new RfCoordinate(-23.551000, -46.634000)).build());
        addAsset(Asset.builder().assetKey("3").assetType("SUBESTACAO").coordinate(new RfCoordinate(-23.552000, -46.635000)).build());

        addAsset(Asset.builder().assetKey("CAMP-SUB-1").assetType("SUBESTACAO").coordinate(new RfCoordinate(-22.9068, -47.0616)).build());
        addAsset(Asset.builder().assetKey("CAMP-REL-1").assetType("RELIGADOR").coordinate(new RfCoordinate(-22.9040, -47.0630)).build());
        addAsset(Asset.builder().assetKey("CAMP-REL-2").assetType("RELIGADOR").coordinate(new RfCoordinate(-22.9090, -47.0600)).build());
        addAsset(Asset.builder().assetKey("CAMP-TR-1").assetType("TRAFO").coordinate(new RfCoordinate(-22.9055, -47.0590)).build());
        addAsset(Asset.builder().assetKey("CAMP-TR-2").assetType("TRAFO").coordinate(new RfCoordinate(-22.9080, -47.0640)).build());
        addAsset(Asset.builder().assetKey("CAMP-POS-1").assetType("POSTE").coordinate(new RfCoordinate(-22.9060, -47.0610)).build());
        addAsset(Asset.builder().assetKey("CAMP-POS-2").assetType("POSTE").coordinate(new RfCoordinate(-22.9075, -47.0625)).build());
        addAsset(Asset.builder().assetKey("CAMP-POS-3").assetType("POSTE").coordinate(new RfCoordinate(-22.9050, -47.0635)).build());
        addAsset(Asset.builder().assetKey("CAMP-POS-4").assetType("POSTE").coordinate(new RfCoordinate(-22.9085, -47.0595)).build());
        
        this.minLat = -25.0;
        this.maxLat = -20.0;
        this.minLon = -53.0;
        this.maxLon = -44.0;
    }

    public List<Asset> getAllAssets() {
        synchronized (assetsByKey) {
            return new ArrayList<>(assetsByKey.values());
        }
    }

    public void addAsset(Asset asset) {
        addAsset(null, asset);
    }

    public void addAsset(String distribuidora, Asset asset) {
        if (asset != null && asset.getAssetKey() != null) {
            String key = (distribuidora != null && !distribuidora.isBlank() ? distribuidora + ":" : "") + asset.getAssetKey();
            assetsByKey.put(key, asset);
        }
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
