package com.backend.tecsys.scenario.repository;

import com.backend.tecsys.scenario.model.Asset;
import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.scenario.repository.IAssetRepository;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;

@Repository
@Profile("mock")
public class MockAssetRepository implements IAssetRepository {

    private static final double BASE_LATITUDE = -22.0000;
    private static final double BASE_LONGITUDE = -47.0000;
    private static final double GRID_STEP_DEGREES = 0.0040;
    private static final int COLUMNS = 5;
    private static final int ASSET_COUNT = 20;
    private static final String[] ASSET_TYPES = {"POSTE", "UCBT", "UCMT", "SSDMT", "SUB"};

    @Override
    public List<Asset> findByUtilityId(Long utilityId) {
        List<Asset> assets = new ArrayList<>();

        for (int index = 0; index < ASSET_COUNT; index++) {
            int row = index / COLUMNS;
            int column = index % COLUMNS;

            double latitude = BASE_LATITUDE + row * GRID_STEP_DEGREES;
            double longitude = BASE_LONGITUDE + column * GRID_STEP_DEGREES;

            assets.add(Asset.builder()
                    .assetKey("ASSET-" + (index + 1))
                    .assetType(ASSET_TYPES[index % ASSET_TYPES.length])
                    .utilityId(utilityId)
                    .coordinate(new RfCoordinate(latitude, longitude))
                    .build());
        }

        return assets;
    }
}
