package com.backend.tecsys.scenario.repository;

import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.scenario.model.GatewayCoverage;
import com.backend.tecsys.scenario.model.Scenario;
import com.backend.tecsys.scenario.model.ScenarioSelectedGateway;
import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class ScenarioSnapshotGatewayTest {

    private static Map<String, Object> snapshotGateway(
            double lat, double lon, String assetKey, String geometry, int covered, double margin) {
        Map<String, Object> gateway = new LinkedHashMap<>();
        gateway.put("candidateId", 1);
        gateway.put("latitude", lat);
        gateway.put("longitude", lon);
        gateway.put("assetKey", assetKey);
        gateway.put("coverageGeometryGeoJson", geometry);
        gateway.put("coveredAssetCount", covered);
        gateway.put("averageLinkMarginDb", margin);
        gateway.put("coverageRadiusMeters", 800.0);
        gateway.put("shadowedAssetKeys", List.of("S1"));
        return gateway;
    }

    private static ScenarioSelectedGateway loaded(long candidateId, double lat, double lon) {
        return ScenarioSelectedGateway.builder()
                .candidateId(candidateId)
                .coordinate(new RfCoordinate(lat, lon))
                .build();
    }

    @Test
    void reattachesGeometryAndMetricsByCoordinatesEvenWhenCandidateIdsAndOrderDiffer() {
        // O candidateId gravado ao salvar (id do candidato persistido) nao e o original do snapshot,
        // e o banco nao garante a ordem: so as coordenadas identificam o gateway.
        ScenarioSelectedGateway second = loaded(902, -10.91, -37.01);
        ScenarioSelectedGateway first = loaded(901, -10.90, -37.00);
        Scenario scenario = Scenario.builder().selectedGateways(List.of(second, first)).build();

        ScenarioSnapshotGatewayHelper.apply(scenario, List.of(
                snapshotGateway(-10.90, -37.00, "POSTE::A", "{\"type\":\"Polygon\"}", 420, 7.3),
                snapshotGateway(-10.91, -37.01, "POSTE::B", null, 15, 2.0)));

        assertEquals("POSTE::A", first.getAssetKey());
        assertEquals("{\"type\":\"Polygon\"}", first.getCoverageGeometryGeoJson());
        assertEquals(420, first.getCoveredAssetCount());
        assertEquals(7.3, first.getAverageLinkMarginDb());
        assertEquals(List.of("S1"), first.getShadowedAssetKeys());
        assertEquals(800.0, first.getCoverageRadiusMeters());

        assertEquals("POSTE::B", second.getAssetKey());
        assertNull(second.getCoverageGeometryGeoJson());
        assertEquals(15, second.getCoveredAssetCount());
    }

    @Test
    void leavesGatewayUntouchedWhenNoSnapshotMatchesItsCoordinates() {
        ScenarioSelectedGateway gateway = loaded(5, -1.0, -1.0);
        Scenario scenario = Scenario.builder().selectedGateways(List.of(gateway)).build();

        ScenarioSnapshotGatewayHelper.apply(scenario, List.of(
                snapshotGateway(-10.90, -37.00, "POSTE::A", "{}", 1, 1.0)));

        assertNull(gateway.getAssetKey());
        assertNull(gateway.getCoveredAssetCount());
    }

    @Test
    void averageReceivedPowerIsNullWhenGatewayCoversNothing() {
        assertNull(GatewayCoverage.builder().build().averageReceivedPowerDbm());

        GatewayCoverage coverage = GatewayCoverage.builder().build();
        coverage.getReceivedPowerDbmByAssetKey().put("a", -100.0);
        coverage.getReceivedPowerDbmByAssetKey().put("b", -110.0);
        assertEquals(-105.0, coverage.averageReceivedPowerDbm());
    }

    /** Acesso ao metodo de pacote do repositorio sem precisar de JdbcTemplate. */
    private static final class ScenarioSnapshotGatewayHelper {
        static void apply(Scenario scenario, List<?> snapshotGateways) {
            PostgresScenarioRepository.applySnapshotGatewayResults(scenario, snapshotGateways);
        }
    }
}
