package com.backend.tecsys.scenario.repository;

import com.backend.tecsys.scenario.model.Asset;

import java.util.List;

public interface IAssetRepository {

    List<Asset> findByUtilityId(Long utilityId);

    List<Asset> findWithinRadius(double latitude, double longitude, double radiusMeters);

    /**
     * Todos os ativos dentro do raio, sem truncamento. Usado pela simulação como
     * universo de cobertura: limitar por uma amostra arbitrária distorce o
     * percentual de cobertura e torna a meta inalcançável.
     */
    List<Asset> findAllWithinRadius(double latitude, double longitude, double radiusMeters);
}
