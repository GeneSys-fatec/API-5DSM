package com.backend.tecsys.scenario.model;

/** Ativo de um cenário salvo, com posição e se foi coberto, para reabrir o resultado no mapa. */
public record ScenarioAssetLocation(
        String assetKey,
        String type,
        double latitude,
        double longitude,
        boolean covered,
        Long gatewayCandidateId) {
}
