package com.backend.tecsys.radio.service;

import com.backend.tecsys.radio.model.PropagationInput;
import com.backend.tecsys.radio.model.RfParameter;
import com.backend.tecsys.radio.model.TerrainProfile;
import com.backend.tecsys.radio.repository.TerrainProfileProvider;
import com.backend.tecsys.radio.service.TerrainLineOfSightAnalyzer.TerrainEvaluation;
import com.backend.tecsys.radio.exception.UnavailableTerrainDataException;
import com.backend.tecsys.scenario.model.Asset;
import com.backend.tecsys.scenario.model.GatewayCandidate;
import com.backend.tecsys.scenario.model.GatewayCoverage;
import com.backend.tecsys.scenario.model.PropagationModelType;
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
    private final FreeSpacePathLossModel freeSpacePathLossModel;
    private final TerrainLineOfSightAnalyzer terrainAnalyzer;

    public RadioCoverageCalculator(
            LinkBudgetCalculator linkBudgetCalculator,
            TerrainProfileProvider terrainProfileProvider,
            RfCoverageRadiusCalculator rfCoverageRadiusCalculator,
            FreeSpacePathLossModel freeSpacePathLossModel,
            TerrainLineOfSightAnalyzer terrainAnalyzer) {
        this.linkBudgetCalculator = linkBudgetCalculator;
        this.terrainProfileProvider = terrainProfileProvider;
        this.rfCoverageRadiusCalculator = rfCoverageRadiusCalculator;
        this.freeSpacePathLossModel = freeSpacePathLossModel;
        this.terrainAnalyzer = terrainAnalyzer;
    }

    public GatewayCoverage calculateCoverage(
            GatewayCandidate candidate,
            List<Asset> assets,
            RfParameter rfParameter,
            PropagationModel propagationModel) {

        double maximumCoverageRadiusMeters =
                rfCoverageRadiusCalculator.calculateRadiusMeters(rfParameter, propagationModel);
        boolean terrainModel = propagationModel.type() == PropagationModelType.ITM_LONGLEY_RICE;
        double furthestCoveredAssetDistanceMeters = 0.0;
        Map<String, Double> receivedPowerByAssetKey = new LinkedHashMap<>();
        Set<String> coveredAssetKeys = new LinkedHashSet<>();
        Set<String> shadowedAssetKeys = new LinkedHashSet<>();
        List<Asset> coveredAssets = new java.util.ArrayList<>();

        for (Asset asset : assets) {
            double distanceM = Math.max(
                    GeoDistanceCalculator.distanceMeters(candidate.getCoordinate(), asset.getCoordinate()),
                    MINIMUM_DISTANCE_M);

            if (distanceM > maximumCoverageRadiusMeters) {
                continue;
            }

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

            TerrainEvaluation terrain = terrainAnalyzer.evaluate(input);
            if (terrain.shadowed()) {
                shadowedAssetKeys.add(asset.getAssetKey());
                continue;
            }

            double propagationLossDb;
            try {
                propagationLossDb = propagationModel.calculatePropagationLossDb(input);
            } catch (UnavailableTerrainDataException unavailableTerrainData) {
                if (propagationModel.type() == PropagationModelType.ITM_LONGLEY_RICE) {
                    throw unavailableTerrainData;
                }
                propagationLossDb = freeSpacePathLossModel.calculatePropagationLossDb(input);
            }
            double receivedPowerDbm = linkBudgetCalculator.receivedPowerDbm(rfParameter, propagationLossDb);

            if (linkBudgetCalculator.isCovered(receivedPowerDbm, rfParameter)) {
                receivedPowerByAssetKey.put(asset.getAssetKey(), receivedPowerDbm);
                coveredAssetKeys.add(asset.getAssetKey());
                coveredAssets.add(asset);
                furthestCoveredAssetDistanceMeters = Math.max(
                        furthestCoveredAssetDistanceMeters, distanceM);
            }
        }

        return GatewayCoverage.builder()
                .candidate(candidate)
                .coverageRadiusMeters(terrainModel
                        ? furthestCoveredAssetDistanceMeters
                        : maximumCoverageRadiusMeters)
                .receivedPowerDbmByAssetKey(receivedPowerByAssetKey)
                .coveredAssetKeys(coveredAssetKeys)
                .shadowedAssetKeys(shadowedAssetKeys)
                .coverageGeometryGeoJson(coverageGeometry(candidate, coveredAssets))
                .build();
    }

    private String coverageGeometry(GatewayCandidate candidate, List<Asset> assets) {
        if (assets.size() < 3) {
            return null;
        }
        List<double[]> points = assets.stream()
                .map(asset -> new double[]{asset.getCoordinate().longitude(), asset.getCoordinate().latitude()})
                .sorted((left, right) -> Double.compare(left[0], right[0]))
                .toList();
        List<double[]> hull = new java.util.ArrayList<>();
        for (double[] point : points) {
            while (hull.size() >= 2 && cross(hull.get(hull.size() - 2), hull.get(hull.size() - 1), point) <= 0) {
                hull.remove(hull.size() - 1);
            }
            hull.add(point);
        }
        int lowerSize = hull.size();
        for (int index = points.size() - 2; index >= 0; index--) {
            double[] point = points.get(index);
            while (hull.size() > lowerSize && cross(hull.get(hull.size() - 2), hull.get(hull.size() - 1), point) <= 0) {
                hull.remove(hull.size() - 1);
            }
            hull.add(point);
        }
        if (hull.size() <= 3) {
            return null;
        }
        hull.remove(hull.size() - 1);
        StringBuilder json = new StringBuilder("{\"type\":\"Polygon\",\"coordinates\":[[");
        for (int index = 0; index <= hull.size(); index++) {
            double[] point = hull.get(index % hull.size());
            if (index > 0) {
                json.append(',');
            }
            json.append('[').append(point[0]).append(',').append(point[1]).append(']');
        }
        return json.append("]]}").toString();
    }

    private double cross(double[] origin, double[] first, double[] second) {
        return (first[0] - origin[0]) * (second[1] - origin[1])
                - (first[1] - origin[1]) * (second[0] - origin[0]);
    }

    public double calculateCoverageRadius(RfParameter rfParameter, PropagationModel propagationModel) {
        return rfCoverageRadiusCalculator.calculateRadiusMeters(rfParameter, propagationModel);
    }
}
