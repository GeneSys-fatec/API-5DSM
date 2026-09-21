package com.backend.tecsys.scenario.repository;

import com.backend.tecsys.scenario.model.Asset;

import java.util.List;

public interface IAssetRepository {

    List<Asset> findByUtilityId(Long utilityId);
}
