package com.backend.tecsys.domain.repository;

import com.backend.tecsys.domain.model.Asset;

import java.util.List;

public interface IAssetRepository {

    List<Asset> findByUtilityId(Long utilityId);
}
