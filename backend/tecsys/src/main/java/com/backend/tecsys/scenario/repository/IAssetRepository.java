package com.backend.tecsys.scenario.repository;

import com.backend.tecsys.scenario.model.Asset;

import java.util.List;
import java.util.UUID;

public interface IAssetRepository {

    List<Asset> findByImportId(UUID importId);

    List<Asset> findWithinRadius(UUID importId, double latitude, double longitude, double radiusMeters);

    List<Asset> findAllWithinRadius(UUID importId, double latitude, double longitude, double radiusMeters);
}
