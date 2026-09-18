package com.backend.tecsys.application.service;

import com.backend.tecsys.domain.model.GatewayCoverage;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

@Service
public class GatewaySelectionService {

    public SelectionResult select(
            List<GatewayCoverage> coverages,
            int totalAssets,
            double coverageTargetPct,
            int maxGateways) {

        int requiredAssets = (int) Math.ceil(totalAssets * coverageTargetPct / 100.0);
        Set<String> coveredAssetKeys = new LinkedHashSet<>();
        List<GatewayCoverage> remaining = new ArrayList<>(coverages);
        List<GatewayCoverage> selected = new ArrayList<>();

        while (!remaining.isEmpty()
                && selected.size() < maxGateways
                && coveredAssetKeys.size() < requiredAssets) {

            GatewayCoverage best = null;
            int bestGain = 0;

            for (GatewayCoverage coverage : remaining) {
                int gain = 0;
                for (String assetKey : coverage.getCoveredAssetKeys()) {
                    if (!coveredAssetKeys.contains(assetKey)) {
                        gain++;
                    }
                }

                if (gain > bestGain) {
                    bestGain = gain;
                    best = coverage;
                }
            }

            if (best == null) {
                break;
            }

            selected.add(best);
            remaining.remove(best);
            coveredAssetKeys.addAll(best.getCoveredAssetKeys());
        }

        boolean targetReached = coveredAssetKeys.size() >= requiredAssets;
        return new SelectionResult(selected, coveredAssetKeys, targetReached);
    }

    public record SelectionResult(
            List<GatewayCoverage> selectedCoverages,
            Set<String> coveredAssetKeys,
            boolean targetReached) {
    }
}
