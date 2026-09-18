package com.backend.tecsys.application.service;

import com.backend.tecsys.domain.model.Asset;
import com.backend.tecsys.domain.model.GatewayCandidate;
import com.backend.tecsys.domain.model.GatewayCoverage;
import com.backend.tecsys.domain.model.RfParameter;
import com.backend.tecsys.domain.rf.GeoDistanceCalculator;
import com.backend.tecsys.domain.rf.LinkBudgetCalculator;
import com.backend.tecsys.domain.rf.PropagationInput;
import com.backend.tecsys.domain.rf.PropagationModel;
import com.backend.tecsys.domain.rf.TerrainProfile;
import com.backend.tecsys.domain.rf.TerrainProfileProvider;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class RadioCoverageCalculator {

    private static final double MINIMUM_DISTANCE_M = 1.0;

    private final LinkBudgetCalculator linkBudgetCalculator;
    private final TerrainProfileProvider terrainProfileProvider;

    public RadioCoverageCalculator(
            LinkBudgetCalculator linkBudgetCalculator,
            TerrainProfileProvider terrainProfileProvider) {
        this.linkBudgetCalculator = linkBudgetCalculator;
        this.terrainProfileProvider = terrainProfileProvider;
    }

    public GatewayCoverage calculateCoverage(
            GatewayCandidate candidate,
            List<Asset> assets,
            RfParameter rfParameter,
            PropagationModel propagationModel) {

        Map<String, Double> receivedPowerByAssetKey = new LinkedHashMap<>();
        Set<String> coveredAssetKeys = new LinkedHashSet<>();

        for (Asset asset : assets) {
            double distanceM = Math.max(
                    GeoDistanceCalculator.distanceMeters(candidate.getCoordinate(), asset.getCoordinate()),
                    MINIMUM_DISTANCE_M);

            TerrainProfile terrainProfile = terrainProfileProvider.getProfile(
                    candidate.getCoordinate(), asset.getCoordinate());

            PropagationInput input = new PropagationInput(
                    rfParameter.getFrequencyMhz(),
                    candidate.getCoordinate(),
                    asset.getCoordinate(),
                    distanceM,
                    rfParameter.getAntennaHeightM(),
                    rfParameter.getDeviceHeightM(),
                    terrainProfile);

            double propagationLossDb = propagationModel.calculatePropagationLossDb(input);
            double receivedPowerDbm = linkBudgetCalculator.receivedPowerDbm(rfParameter, propagationLossDb);

            receivedPowerByAssetKey.put(asset.getAssetKey(), receivedPowerDbm);
            if (linkBudgetCalculator.isCovered(receivedPowerDbm, rfParameter)) {
                coveredAssetKeys.add(asset.getAssetKey());
            }
        }

        return GatewayCoverage.builder()
                .candidate(candidate)
                .receivedPowerDbmByAssetKey(receivedPowerByAssetKey)
                .coveredAssetKeys(coveredAssetKeys)
                .build();
    }
}
