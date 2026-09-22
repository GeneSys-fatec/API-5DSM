package com.backend.tecsys.radio.service;

import com.backend.tecsys.radio.model.PropagationInput;
import com.backend.tecsys.radio.model.RfParameter;
import com.backend.tecsys.radio.model.TerrainProfile;
import com.backend.tecsys.radio.repository.TerrainProfileProvider;
import com.backend.tecsys.scenario.model.Asset;
import com.backend.tecsys.scenario.model.GatewayCandidate;
import com.backend.tecsys.scenario.model.GatewayCoverage;
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
    private final RfCoverageRadiusCalculator rfCoverageRadiusCalculator;

    public RadioCoverageCalculator(
            LinkBudgetCalculator linkBudgetCalculator,
            TerrainProfileProvider terrainProfileProvider,
            RfCoverageRadiusCalculator rfCoverageRadiusCalculator) {
        this.linkBudgetCalculator = linkBudgetCalculator;
        this.terrainProfileProvider = terrainProfileProvider;
        this.rfCoverageRadiusCalculator = rfCoverageRadiusCalculator;
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

        double coverageRadiusMeters = rfCoverageRadiusCalculator.calculateRadiusMeters(rfParameter, propagationModel);

        return GatewayCoverage.builder()
                .candidate(candidate)
                .coverageRadiusMeters(coverageRadiusMeters)
                .receivedPowerDbmByAssetKey(receivedPowerByAssetKey)
                .coveredAssetKeys(coveredAssetKeys)
                .build();
    }

    public double calculateCoverageRadius(RfParameter rfParameter, PropagationModel propagationModel) {
        return rfCoverageRadiusCalculator.calculateRadiusMeters(rfParameter, propagationModel);
    }
}
