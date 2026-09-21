package com.backend.tecsys.scenario.service;

import com.backend.tecsys.scenario.model.Asset;
import com.backend.tecsys.scenario.model.ScenarioIndicator;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class ScenarioIndicatorCalculator {

    public ScenarioIndicator calculate(
            List<Asset> assets,
            Set<String> coveredAssetKeys,
            int usedGatewayCount,
            double totalEstimatedCost,
            int processingTimeMs,
            boolean targetReached) {

        int totalAssets = assets.size();
        double totalCoveragePct = totalAssets == 0
                ? 0.0
                : coveredAssetKeys.size() * 100.0 / totalAssets;

        Map<String, Integer> totalByAssetType = new LinkedHashMap<>();
        Map<String, Integer> coveredByAssetType = new LinkedHashMap<>();

        for (Asset asset : assets) {
            totalByAssetType.merge(asset.getAssetType(), 1, Integer::sum);
            if (coveredAssetKeys.contains(asset.getAssetKey())) {
                coveredByAssetType.merge(asset.getAssetType(), 1, Integer::sum);
            }
        }

        Map<String, Double> coveragePctByAssetType = new LinkedHashMap<>();
        totalByAssetType.forEach((assetType, total) -> {
            int covered = coveredByAssetType.getOrDefault(assetType, 0);
            coveragePctByAssetType.put(assetType, total == 0 ? 0.0 : covered * 100.0 / total);
        });

        return ScenarioIndicator.builder()
                .totalCoveragePct(totalCoveragePct)
                .coveragePctByAssetType(coveragePctByAssetType)
                .usedGatewayCount(usedGatewayCount)
                .totalEstimatedCost(totalEstimatedCost)
                .processingTimeMs(processingTimeMs)
                .targetReached(targetReached)
                .calculatedAt(LocalDateTime.now())
                .build();
    }
}
