package com.backend.tecsys;

import com.backend.tecsys.radio.exception.UnavailableTerrainDataException;
import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.radio.model.RfParameter;
import com.backend.tecsys.radio.model.TerrainProfile;
import com.backend.tecsys.radio.repository.TerrainProfileProvider;
import com.backend.tecsys.radio.service.FreeSpacePathLossModel;
import com.backend.tecsys.radio.service.GeoDistanceCalculator;
import com.backend.tecsys.radio.service.ItmLongleyRiceModel;
import com.backend.tecsys.radio.service.LinkBudgetCalculator;
import com.backend.tecsys.radio.service.RadioCoverageCalculator;
import com.backend.tecsys.radio.service.RfCoverageRadiusCalculator;
import com.backend.tecsys.radio.service.TerrainLineOfSightAnalyzer;
import com.backend.tecsys.scenario.model.Asset;
import com.backend.tecsys.scenario.model.GatewayCandidate;
import com.backend.tecsys.scenario.model.GatewayCoverage;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RadioCoverageCalculatorTerrainTest {

    private static final RfCoordinate GATEWAY_COORDINATE = new RfCoordinate(-22.0, -47.0);
    private static final RfCoordinate ASSET_COORDINATE = new RfCoordinate(-22.0, -47.001);

    @Test
    void shouldCalculateItmCoverageAndReportTerrainBasedRadius() {
        double distance = GeoDistanceCalculator.distanceMeters(
                GATEWAY_COORDINATE, ASSET_COORDINATE);
        TerrainProfileProvider terrainProvider = (from, to) ->
                new TerrainProfile(new double[]{0.0, 0.0, 0.0}, distance / 2.0);
        RadioCoverageCalculator calculator = createCalculator(terrainProvider);

        GatewayCoverage coverage = calculator.calculateCoverage(
                gatewayCandidate(),
                List.of(asset()),
                RfParameter.defaults(),
                new ItmLongleyRiceModel());

        assertTrue(coverage.getCoveredAssetKeys().contains("asset-1"));
        assertEquals(distance, coverage.getCoverageRadiusMeters(), 0.1);
    }

    @Test
    void shouldNotUseFreeSpaceWhenItmTerrainProfileIsUnavailable() {
        RadioCoverageCalculator calculator = createCalculator(
                (from, to) -> TerrainProfile.empty());

        assertThrows(
                UnavailableTerrainDataException.class,
                () -> calculator.calculateCoverage(
                        gatewayCandidate(),
                        List.of(asset()),
                        RfParameter.defaults(),
                        new ItmLongleyRiceModel()));
    }

    private RadioCoverageCalculator createCalculator(TerrainProfileProvider terrainProvider) {
        LinkBudgetCalculator linkBudgetCalculator = new LinkBudgetCalculator();
        return new RadioCoverageCalculator(
                linkBudgetCalculator,
                terrainProvider,
                new RfCoverageRadiusCalculator(linkBudgetCalculator),
                new FreeSpacePathLossModel(),
                new TerrainLineOfSightAnalyzer());
    }

    private GatewayCandidate gatewayCandidate() {
        return GatewayCandidate.builder()
                .id(1L)
                .assetKey("gateway-1")
                .coordinate(GATEWAY_COORDINATE)
                .build();
    }

    private Asset asset() {
        return Asset.builder()
                .assetKey("asset-1")
                .assetType("poste")
                .coordinate(ASSET_COORDINATE)
                .build();
    }
}
