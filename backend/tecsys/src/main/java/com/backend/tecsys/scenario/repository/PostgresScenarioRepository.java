package com.backend.tecsys.scenario.repository;

import com.backend.tecsys.scenario.exception.ScenarioPersistenceException;
import com.backend.tecsys.scenario.model.Scenario;
import com.backend.tecsys.scenario.model.ScenarioAssetCoverage;
import com.backend.tecsys.scenario.model.ScenarioIndicator;
import com.backend.tecsys.scenario.model.ScenarioSelectedGateway;
import com.backend.tecsys.scenario.repository.IScenarioRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.sql.PreparedStatement;
import java.sql.Types;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Repository
@Profile("!mock")
public class PostgresScenarioRepository implements IScenarioRepository {

    private static final String INSERT_SCENARIO = """
            INSERT INTO app.cenario
                (nome, usuario_id, distribuidora_id, regiao_nome, area_geom,
                 meta_cobertura_pct, max_gateways, custo_unitario_gateway,
                 parametro_rf_id, status, processado_em, tempo_processamento_ms)
            VALUES (?,
                    COALESCE((SELECT id FROM app.usuario WHERE id = ?), (SELECT id FROM app.usuario LIMIT 1)),
                    COALESCE((SELECT id FROM app.distribuidora WHERE id = ?), (SELECT id FROM app.distribuidora LIMIT 1)),
                    ?, ST_GeomFromText(?, 4326), ?, ?, ?, NULL, ?, now(), ?)
            """;

    private static final String INSERT_SELECTED_GATEWAY = """
            INSERT INTO app.cenario_gateway_selecionado
                (cenario_id, candidato_gateway_id, geom_final, ajustado_manualmente)
            VALUES (?, ?, ST_GeomFromText(?, 4326), ?)
            ON CONFLICT (cenario_id, candidato_gateway_id) DO UPDATE
            SET geom_final = EXCLUDED.geom_final
            """;

    private static final String INSERT_ASSET_COVERAGE = """
            INSERT INTO app.cenario_cobertura_ativo
                (cenario_id, ativo_key, coberto, gateway_selecionado_id)
            VALUES (?, ?, ?, ?)
            """;

    private static final String INSERT_INDICATOR = """
            INSERT INTO app.cenario_indicador
                (cenario_id, pct_cobertura_total, pct_cobertura_por_tipo,
                 qtd_gateways_utilizados, custo_total_estimado,
                 tempo_processamento_ms, meta_atingida)
            VALUES (?, ?, CAST(? AS jsonb), ?, ?, ?, ?)
            """;

    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public PostgresScenarioRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public Scenario save(Scenario scenario) {
        try {
            Long scenarioId = insertScenario(scenario);
            scenario.setId(scenarioId);

            Map<Long, Long> selectedGatewayIdByCandidate = insertSelectedGateways(scenarioId, scenario.getSelectedGateways());
            insertAssetCoverages(scenarioId, scenario.getAssetCoverages(), selectedGatewayIdByCandidate);
            insertIndicator(scenarioId, scenario.getIndicator());

            return scenario;
        } catch (ScenarioPersistenceException e) {
            throw e;
        } catch (Exception e) {
            throw new ScenarioPersistenceException("Falha ao persistir o cenário de simulação: " + e.getMessage(), e);
        }
    }

    private Long insertScenario(Scenario scenario) {
        KeyHolder keyHolder = new GeneratedKeyHolder();

        jdbcTemplate.update(connection -> {
            PreparedStatement statement = connection.prepareStatement(INSERT_SCENARIO, new String[]{"id"});
            statement.setString(1, scenario.getName());
            statement.setLong(2, scenario.getUserId());
            statement.setLong(3, scenario.getUtilityId());
            statement.setString(4, scenario.getRegionName());
            statement.setString(5, buildAreaWkt(scenario.getSelectedGateways()));
            statement.setBigDecimal(6, BigDecimal.valueOf(scenario.getCoverageTargetPct()));
            statement.setInt(7, scenario.getMaxGateways());
            if (scenario.getGatewayUnitCost() != null) {
                statement.setBigDecimal(8, BigDecimal.valueOf(scenario.getGatewayUnitCost()));
            } else {
                statement.setNull(8, Types.NUMERIC);
            }
            statement.setString(9, scenario.getStatus());
            if (scenario.getProcessingTimeMs() != null) {
                statement.setInt(10, scenario.getProcessingTimeMs());
            } else {
                statement.setNull(10, Types.INTEGER);
            }
            return statement;
        }, keyHolder);

        return keyHolder.getKey().longValue();
    }

    private Map<Long, Long> insertSelectedGateways(Long scenarioId, List<ScenarioSelectedGateway> selectedGateways) {
        Map<Long, Long> selectedGatewayIdByCandidate = new HashMap<>();
        Map<Long, Long> mappedCandidateIds = new HashMap<>();

        for (ScenarioSelectedGateway gateway : selectedGateways) {
            Long originalCandidateId = gateway.getCandidateId();
            Long effectiveCandidateId = mappedCandidateIds.computeIfAbsent(originalCandidateId, k -> {
                try {
                    return jdbcTemplate.queryForObject(
                        "INSERT INTO app.candidato_gateway (distribuidora_id, origem, ativo_key, geom, custo_estimado) " +
                        "VALUES (COALESCE((SELECT distribuidora_id FROM app.cenario WHERE id = ?), (SELECT id FROM app.distribuidora LIMIT 1)), 'manual', NULL, ST_GeomFromText(?, 4326), 1500.0) RETURNING id",
                        Long.class,
                        scenarioId,
                        toPointWkt(gateway.getCoordinate().longitude(), gateway.getCoordinate().latitude())
                    );
                } catch (Exception e) {
                    System.err.println("Failed to insert candidato_gateway: " + e.getMessage());
                    return originalCandidateId;
                }
            });

            KeyHolder keyHolder = new GeneratedKeyHolder();

            jdbcTemplate.update(connection -> {
                PreparedStatement statement = connection.prepareStatement(INSERT_SELECTED_GATEWAY, new String[]{"id"});
                statement.setLong(1, scenarioId);
                statement.setLong(2, effectiveCandidateId);
                statement.setString(3, toPointWkt(gateway.getCoordinate().longitude(), gateway.getCoordinate().latitude()));
                statement.setBoolean(4, gateway.isManuallyAdjusted());
                return statement;
            }, keyHolder);

            Long selectedGatewayId = (keyHolder.getKey() != null) ? keyHolder.getKey().longValue() : effectiveCandidateId;
            gateway.setId(selectedGatewayId);
            gateway.setScenarioId(scenarioId);
            if (originalCandidateId != null && selectedGatewayId != null) {
                selectedGatewayIdByCandidate.put(originalCandidateId, selectedGatewayId);
            }
        }

        return selectedGatewayIdByCandidate;
    }

    private void insertAssetCoverages(
            Long scenarioId,
            List<ScenarioAssetCoverage> assetCoverages,
            Map<Long, Long> selectedGatewayIdByCandidate) {

        List<ScenarioAssetCoverage> toInsert = assetCoverages.size() > 500
                ? assetCoverages.subList(0, 500)
                : assetCoverages;

        jdbcTemplate.batchUpdate(INSERT_ASSET_COVERAGE, toInsert, 100, (statement, coverage) -> {
            Long selectedGatewayId = coverage.getSelectedCandidateId() != null
                    ? selectedGatewayIdByCandidate.get(coverage.getSelectedCandidateId())
                    : null;

            coverage.setScenarioId(scenarioId);
            coverage.setSelectedGatewayId(selectedGatewayId);

            statement.setLong(1, scenarioId);
            statement.setString(2, coverage.getAssetKey());
            statement.setBoolean(3, coverage.isCovered());
            if (selectedGatewayId != null) {
                statement.setLong(4, selectedGatewayId);
            } else {
                statement.setNull(4, Types.BIGINT);
            }
        });
    }

    private void insertIndicator(Long scenarioId, ScenarioIndicator indicator) {
        if (indicator == null) {
            return;
        }

        indicator.setScenarioId(scenarioId);

        jdbcTemplate.update(INSERT_INDICATOR, statement -> {
            statement.setLong(1, scenarioId);
            statement.setBigDecimal(2, BigDecimal.valueOf(indicator.getTotalCoveragePct()));
            statement.setString(3, serializeCoverageByAssetType(indicator.getCoveragePctByAssetType()));
            statement.setInt(4, indicator.getUsedGatewayCount());
            if (indicator.getTotalEstimatedCost() != null) {
                statement.setBigDecimal(5, BigDecimal.valueOf(indicator.getTotalEstimatedCost()));
            } else {
                statement.setNull(5, Types.NUMERIC);
            }
            if (indicator.getProcessingTimeMs() != null) {
                statement.setInt(6, indicator.getProcessingTimeMs());
            } else {
                statement.setNull(6, Types.INTEGER);
            }
            statement.setBoolean(7, indicator.isTargetReached());
        });
    }

    private String serializeCoverageByAssetType(Map<String, Double> coverageByAssetType) {
        try {
            return objectMapper.writeValueAsString(coverageByAssetType == null ? Map.of() : coverageByAssetType);
        } catch (Exception e) {
            return "{}";
        }
    }

    private String buildAreaWkt(List<ScenarioSelectedGateway> selectedGateways) {
        if (selectedGateways == null || selectedGateways.isEmpty()) {
            return "POLYGON((-0.01 -0.01, 0.01 -0.01, 0.01 0.01, -0.01 0.01, -0.01 -0.01))";
        }

        double minLatitude = Double.POSITIVE_INFINITY;
        double maxLatitude = Double.NEGATIVE_INFINITY;
        double minLongitude = Double.POSITIVE_INFINITY;
        double maxLongitude = Double.NEGATIVE_INFINITY;

        for (ScenarioSelectedGateway gateway : selectedGateways) {
            double latitude = gateway.getCoordinate().latitude();
            double longitude = gateway.getCoordinate().longitude();
            minLatitude = Math.min(minLatitude, latitude);
            maxLatitude = Math.max(maxLatitude, latitude);
            minLongitude = Math.min(minLongitude, longitude);
            maxLongitude = Math.max(maxLongitude, longitude);
        }

        double padding = 0.001;
        return "POLYGON(("
                + (minLongitude - padding) + " " + (minLatitude - padding) + ", "
                + (maxLongitude + padding) + " " + (minLatitude - padding) + ", "
                + (maxLongitude + padding) + " " + (maxLatitude + padding) + ", "
                + (minLongitude - padding) + " " + (maxLatitude + padding) + ", "
                + (minLongitude - padding) + " " + (minLatitude - padding) + "))";
    }

    private String toPointWkt(double longitude, double latitude) {
        return "POINT(" + longitude + " " + latitude + ")";
    }
}
