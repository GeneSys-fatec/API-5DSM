package com.backend.tecsys.scenario.repository;

import com.backend.tecsys.radio.model.RfParameter;
import com.backend.tecsys.scenario.exception.ScenarioPersistenceException;
import com.backend.tecsys.scenario.model.PropagationModelType;
import com.backend.tecsys.scenario.model.Scenario;
import com.backend.tecsys.scenario.model.ScenarioAssetLocation;
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
                    ?, ST_GeomFromText(?, 4326), ?, ?, ?, ?, ?, now(), ?)
            """;

    private static final String INSERT_RF_PARAMETER = """
            INSERT INTO app.parametro_rf
                (nome, modelo_propagacao, frequencia_mhz, potencia_dbm, altura_antena_m, raio_cobertura_m, criado_por)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            RETURNING id
            """;

    private static final String INSERT_RELATORIO_SNAPSHOT = """
            INSERT INTO app.cenario_relatorio_snapshot (cenario_id, dados, criado_em)
            VALUES (?, CAST(? AS jsonb), now())
            """;

    private static final String SELECT_SNAPSHOT_BY_SCENARIO = """
            SELECT dados
            FROM app.cenario_relatorio_snapshot
            WHERE cenario_id = ?
            ORDER BY criado_em DESC
            LIMIT 1
            """;

    private static final String SELECT_RF_PARAMETER_BY_ID = """
            SELECT modelo_propagacao, frequencia_mhz, potencia_dbm, altura_antena_m, raio_cobertura_m
            FROM app.parametro_rf
            WHERE id = ?
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

    private static final String SELECT_SCENARIO_BY_ID = """
            SELECT id, nome, usuario_id, distribuidora_id, regiao_nome, ST_AsText(area_geom) as area_wkt,
                   meta_cobertura_pct, max_gateways, custo_unitario_gateway, parametro_rf_id, status,
                   tempo_processamento_ms, processado_em
            FROM app.cenario
            WHERE id = ?
            """;

    private static final String SELECT_SCENARIOS_BY_USER = """
            SELECT id, nome, usuario_id, distribuidora_id, regiao_nome, ST_AsText(area_geom) as area_wkt,
                   meta_cobertura_pct, max_gateways, custo_unitario_gateway, parametro_rf_id, status,
                   tempo_processamento_ms, processado_em
            FROM app.cenario
            WHERE usuario_id = ?
            ORDER BY processado_em DESC
            """;

    private static final String SELECT_SCENARIOS_BY_USER_REGION = """
            SELECT id, nome, usuario_id, distribuidora_id, regiao_nome, ST_AsText(area_geom) as area_wkt,
                   meta_cobertura_pct, max_gateways, custo_unitario_gateway, parametro_rf_id, status,
                   tempo_processamento_ms, processado_em
            FROM app.cenario
            WHERE usuario_id = ? AND regiao_nome = ?
            ORDER BY processado_em DESC
            """;

    private static final String SELECT_INDICATOR_BY_SCENARIO = """
            SELECT pct_cobertura_total, pct_cobertura_por_tipo, qtd_gateways_utilizados,
                   custo_total_estimado, tempo_processamento_ms, meta_atingida
            FROM app.cenario_indicador
            WHERE cenario_id = ?
            """;

    private static final String SELECT_GATEWAYS_BY_SCENARIO = """
            SELECT candidato_gateway_id, ST_Y(geom_final) as lat, ST_X(geom_final) as lon, ajustado_manualmente
            FROM app.cenario_gateway_selecionado
            WHERE cenario_id = ?
            """;

    private static final String SELECT_COVERAGES_BY_SCENARIO = """
            SELECT ativo_key, coberto, gateway_selecionado_id
            FROM app.cenario_cobertura_ativo
            WHERE cenario_id = ?
            """;

    private static final String DELETE_SCENARIO_BY_ID = """
            DELETE FROM app.cenario WHERE id = ?
            """;

    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public PostgresScenarioRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public Scenario save(Scenario scenario) {
        try {
            scenario.setRfParameterId(insertRfParameter(scenario));
            Long scenarioId = insertScenario(scenario);
            scenario.setId(scenarioId);

            Map<Long, Long> selectedGatewayIdByCandidate = insertSelectedGateways(scenarioId, scenario.getSelectedGateways());
            insertAssetCoverages(scenarioId, scenario.getAssetCoverages(), selectedGatewayIdByCandidate);
            insertIndicator(scenarioId, scenario.getIndicator());
            insertRelatorioSnapshot(scenario);

            return scenario;
        } catch (ScenarioPersistenceException e) {
            throw e;
        } catch (Exception e) {
            throw new ScenarioPersistenceException("Falha ao persistir o cenário de simulação: " + e.getMessage(), e);
        }
    }

    private Long insertRfParameter(Scenario scenario) {
        RfParameter rf = scenario.getRfParameter();
        Double coverageRadius = scenario.getCoverageRadiusMeters();
        if (rf == null && coverageRadius == null) {
            return null;
        }

        try {
            return jdbcTemplate.queryForObject(INSERT_RF_PARAMETER, Long.class,
                    scenario.getName() + " - RF",
                    scenario.getPropagationModel() != null ? scenario.getPropagationModel().name() : null,
                    rf != null ? rf.getFrequencyMhz() : null,
                    rf != null ? rf.getTransmitPowerDbm() : null,
                    rf != null ? rf.getAntennaHeightM() : null,
                    coverageRadius,
                    scenario.getUserId());
        } catch (Exception e) {
            // A coluna cenario.parametro_rf_id é opcional: sem RF válido, mantém NULL.
            return null;
        }
    }

    private void insertRelatorioSnapshot(Scenario scenario) {
        try {
            Map<String, Object> snapshot = new HashMap<>();
            if (scenario.getPropagationModel() != null) {
                snapshot.put("propagationModel", scenario.getPropagationModel().name());
            }
            if (scenario.getRfParameter() != null) {
                snapshot.put("rfParameter", objectMapper.convertValue(scenario.getRfParameter(), Map.class));
            }
            if (scenario.getCoverageRadiusMeters() != null) {
                snapshot.put("coverageRadiusMeters", scenario.getCoverageRadiusMeters());
            }
            if (scenario.getAverageRssiDbm() != null) {
                snapshot.put("averageRssiDbm", scenario.getAverageRssiDbm());
            }
            if (scenario.getSelectedGateways() != null && !scenario.getSelectedGateways().isEmpty()) {
                List<Map<String, Object>> gateways = new java.util.ArrayList<>();
                for (ScenarioSelectedGateway gateway : scenario.getSelectedGateways()) {
                    Map<String, Object> g = new HashMap<>();
                    g.put("candidateId", gateway.getCandidateId());
                    g.put("coverageRadiusMeters", gateway.getCoverageRadiusMeters());
                    // Coordenadas identificam o gateway ao reabrir (o candidateId gravado em
                    // cenario_gateway_selecionado e o do candidato persistido, nao o original).
                    if (gateway.getCoordinate() != null) {
                        g.put("latitude", gateway.getCoordinate().latitude());
                        g.put("longitude", gateway.getCoordinate().longitude());
                    }
                    g.put("assetKey", gateway.getAssetKey());
                    g.put("coverageGeometryGeoJson", gateway.getCoverageGeometryGeoJson());
                    g.put("coveredAssetCount", gateway.getCoveredAssetCount());
                    g.put("averageRssiDbm", gateway.getAverageRssiDbm());
                    g.put("averageLinkMarginDb", gateway.getAverageLinkMarginDb());
                    g.put("shadowedAssetKeys", gateway.getShadowedAssetKeys());
                    gateways.add(g);
                }
                snapshot.put("selectedGateways", gateways);
            }

            jdbcTemplate.update(INSERT_RELATORIO_SNAPSHOT,
                    scenario.getId(),
                    objectMapper.writeValueAsString(snapshot));
        } catch (Exception ignored) {
            // O snapshot é um dado complementar; falha não deve interromper a persistência do cenário.
        }
    }

    @Override
    public Scenario findById(Long id) {
        try {
            Scenario scenario = jdbcTemplate.query(SELECT_SCENARIO_BY_ID, rs -> {
                if (!rs.next()) return null;
                return mapRowToScenario(rs);
            }, id);
            if (scenario == null) return null;
            loadScenarioDetails(scenario);
            loadRfParameter(scenario);
            loadRelatorioSnapshot(scenario);
            applyScenarioCoverageRadius(scenario);
            return scenario;
        } catch (Exception e) {
            throw new ScenarioPersistenceException("Falha ao buscar cenário: " + e.getMessage(), e);
        }
    }

    @Override
    public List<Scenario> findAllByUserId(Long userId) {
        try {
            List<Scenario> scenarios = jdbcTemplate.query(SELECT_SCENARIOS_BY_USER, (rs, rowNum) -> mapRowToScenario(rs), userId);
            for (Scenario s : scenarios) {
                loadScenarioIndicator(s);
                loadRfParameter(s);
            }
            return scenarios;
        } catch (Exception e) {
            throw new ScenarioPersistenceException("Falha ao listar cenários: " + e.getMessage(), e);
        }
    }

    @Override
    public List<Scenario> findByUserIdAndRegionName(Long userId, String regionName) {
        try {
            List<Scenario> scenarios = jdbcTemplate.query(SELECT_SCENARIOS_BY_USER_REGION, (rs, rowNum) -> mapRowToScenario(rs), userId, regionName);
            for (Scenario s : scenarios) {
                loadScenarioIndicator(s);
                loadRfParameter(s);
            }
            return scenarios;
        } catch (Exception e) {
            throw new ScenarioPersistenceException("Falha ao listar cenários por região: " + e.getMessage(), e);
        }
    }

    @Override
    public void deleteById(Long id) {
        try {
            jdbcTemplate.update(DELETE_SCENARIO_BY_ID, id);
        } catch (Exception e) {
            throw new ScenarioPersistenceException("Falha ao excluir cenário: " + e.getMessage(), e);
        }
    }

    private Scenario mapRowToScenario(java.sql.ResultSet rs) throws java.sql.SQLException {
        Scenario scenario = new Scenario();
        scenario.setId(rs.getLong("id"));
        scenario.setName(rs.getString("nome"));
        scenario.setUserId(rs.getLong("usuario_id"));
        scenario.setUtilityId(rs.getLong("distribuidora_id"));
        scenario.setRegionName(rs.getString("regiao_nome"));
        scenario.setAreaWkt(rs.getString("area_wkt"));
        scenario.setCoverageTargetPct(rs.getDouble("meta_cobertura_pct"));
        scenario.setMaxGateways(rs.getInt("max_gateways"));
        scenario.setGatewayUnitCost(rs.getObject("custo_unitario_gateway") != null ? rs.getDouble("custo_unitario_gateway") : null);
        scenario.setRfParameterId(rs.getObject("parametro_rf_id") != null ? rs.getLong("parametro_rf_id") : null);
        scenario.setStatus(rs.getString("status"));
        scenario.setProcessingTimeMs(rs.getObject("tempo_processamento_ms") != null ? rs.getInt("tempo_processamento_ms") : null);
        java.sql.Timestamp processadoEm = rs.getTimestamp("processado_em");
        scenario.setProcessedAt(processadoEm != null ? processadoEm.toInstant() : null);
        return scenario;
    }

    private void loadScenarioDetails(Scenario scenario) {
        loadScenarioIndicator(scenario);
        scenario.setSelectedGateways(loadSelectedGateways(scenario.getId()));
        scenario.setAssetCoverages(loadAssetCoverages(scenario.getId()));
    }

    private void loadScenarioIndicator(Scenario scenario) {
        try {
            ScenarioIndicator indicator = jdbcTemplate.query(SELECT_INDICATOR_BY_SCENARIO, rs -> {
                if (!rs.next()) return null;
                ScenarioIndicator ind = ScenarioIndicator.builder()
                        .scenarioId(scenario.getId())
                        .totalCoveragePct(rs.getDouble("pct_cobertura_total"))
                        .coveragePctByAssetType(parseJsonMap(rs.getString("pct_cobertura_por_tipo")))
                        .usedGatewayCount(rs.getInt("qtd_gateways_utilizados"))
                        .totalEstimatedCost(rs.getObject("custo_total_estimado") != null ? rs.getDouble("custo_total_estimado") : null)
                        .processingTimeMs(rs.getObject("tempo_processamento_ms") != null ? rs.getInt("tempo_processamento_ms") : null)
                        .targetReached(rs.getBoolean("meta_atingida"))
                        .build();
                return ind;
            }, scenario.getId());
            scenario.setIndicator(indicator);
        } catch (Exception ignored) {
        }
    }

    private void loadRfParameter(Scenario scenario) {
        if (scenario.getRfParameterId() == null) {
            return;
        }
        try {
            jdbcTemplate.query(SELECT_RF_PARAMETER_BY_ID, rs -> {
                if (!rs.next()) return null;
                String modelo = rs.getString("modelo_propagacao");
                if (modelo != null && !modelo.isBlank()) {
                    try {
                        scenario.setPropagationModel(PropagationModelType.fromValue(modelo));
                    } catch (Exception ignored) {
                    }
                }

                RfParameter snapshotRf = loadSnapshotRfParameter(scenario.getId());
                RfParameter rf = snapshotRf != null ? snapshotRf : RfParameter.defaults();

                if (rs.getObject("frequencia_mhz") != null) {
                    rf.setFrequencyMhz(rs.getDouble("frequencia_mhz"));
                }
                if (rs.getObject("potencia_dbm") != null) {
                    rf.setTransmitPowerDbm(rs.getDouble("potencia_dbm"));
                }
                if (rs.getObject("altura_antena_m") != null) {
                    rf.setAntennaHeightM(rs.getDouble("altura_antena_m"));
                }
                scenario.setRfParameter(rf);

                if (rs.getObject("raio_cobertura_m") != null) {
                    scenario.setCoverageRadiusMeters(rs.getDouble("raio_cobertura_m"));
                }
                return scenario;
            }, scenario.getRfParameterId());
        } catch (Exception ignored) {
        }
    }

    private RfParameter loadSnapshotRfParameter(Long scenarioId) {
        try {
            return jdbcTemplate.query(SELECT_SNAPSHOT_BY_SCENARIO, rs -> {
                if (!rs.next()) return null;
                return parseSnapshotRf(rs.getString("dados"));
            }, scenarioId);
        } catch (Exception e) {
            return null;
        }
    }

    @SuppressWarnings("unchecked")
    private RfParameter parseSnapshotRf(String json) {
        try {
            Map<String, Object> snapshot = objectMapper.readValue(json, Map.class);
            Object rfNode = snapshot.get("rfParameter");
            if (rfNode == null) {
                return null;
            }
            return objectMapper.convertValue(rfNode, RfParameter.class);
        } catch (Exception e) {
            return null;
        }
    }

    private void loadRelatorioSnapshot(Scenario scenario) {
        try {
            String json = jdbcTemplate.query(SELECT_SNAPSHOT_BY_SCENARIO, rs -> {
                if (!rs.next()) return null;
                return rs.getString("dados");
            }, scenario.getId());
            if (json == null || json.isBlank()) {
                return;
            }

            Map<String, Object> snapshot = objectMapper.readValue(json, new com.fasterxml.jackson.core.type.TypeReference<Map<String, Object>>() {});
            if (scenario.getRfParameter() == null && snapshot.containsKey("rfParameter")) {
                scenario.setRfParameter(objectMapper.convertValue(snapshot.get("rfParameter"), RfParameter.class));
            }
            if (snapshot.get("coverageRadiusMeters") instanceof Number radius
                    && scenario.getCoverageRadiusMeters() == null) {
                scenario.setCoverageRadiusMeters(radius.doubleValue());
            }
            if (scenario.getPropagationModel() == null) {
                scenario.setPropagationModel(snapshotPropagationModel(snapshot));
            }
            if (snapshot.get("averageRssiDbm") instanceof Number rssi) {
                scenario.setAverageRssiDbm(rssi.doubleValue());
            }
            if (snapshot.get("selectedGateways") instanceof List<?> gateways) {
                applySnapshotGatewayResults(scenario, gateways);
                Map<Long, Double> radiusByCandidate = new HashMap<>();
                for (Object o : gateways) {
                    if (o instanceof Map<?, ?> g
                            && g.get("candidateId") instanceof Number cid
                            && g.get("coverageRadiusMeters") instanceof Number r) {
                        radiusByCandidate.put(cid.longValue(), r.doubleValue());
                    }
                }
                if (scenario.getSelectedGateways() != null) {
                    for (ScenarioSelectedGateway gateway : scenario.getSelectedGateways()) {
                        Double radius = radiusByCandidate.get(gateway.getCandidateId());
                        if (radius != null) {
                            gateway.setCoverageRadiusMeters(radius);
                        }
                    }
                }
            }
        } catch (Exception ignored) {
        }
    }

    /**
     * Quando o registro de parametros de RF nao foi gravado (parametro_rf_id nulo), o modelo de propagacao
     * so existe no snapshot do cenario. Sem ele o historico reabre com o modelo em branco e o relatorio
     * (que exige o modelo) e rejeitado.
     */
    static PropagationModelType snapshotPropagationModel(Map<String, Object> snapshot) {
        if (snapshot.get("propagationModel") instanceof String name && !name.isBlank()) {
            try {
                return PropagationModelType.fromValue(name);
            } catch (Exception ignored) {
                return null;
            }
        }
        return null;
    }

    /** Reanexa a cada gateway carregado o resultado calculado (geometria, contagens, RSSI), casando pelas coordenadas. */
    static void applySnapshotGatewayResults(Scenario scenario, List<?> snapshotGateways) {
        if (scenario.getSelectedGateways() == null) {
            return;
        }
        final double tolerance = 1e-6;
        for (ScenarioSelectedGateway gateway : scenario.getSelectedGateways()) {
            if (gateway.getCoordinate() == null) {
                continue;
            }
            for (Object o : snapshotGateways) {
                if (!(o instanceof Map<?, ?> g)
                        || !(g.get("latitude") instanceof Number lat)
                        || !(g.get("longitude") instanceof Number lon)) {
                    continue;
                }
                if (Math.abs(lat.doubleValue() - gateway.getCoordinate().latitude()) > tolerance
                        || Math.abs(lon.doubleValue() - gateway.getCoordinate().longitude()) > tolerance) {
                    continue;
                }
                gateway.setAssetKey(g.get("assetKey") instanceof String v ? v : null);
                gateway.setCoverageGeometryGeoJson(
                        g.get("coverageGeometryGeoJson") instanceof String v ? v : null);
                gateway.setCoveredAssetCount(
                        g.get("coveredAssetCount") instanceof Number v ? v.intValue() : null);
                gateway.setAverageRssiDbm(
                        g.get("averageRssiDbm") instanceof Number v ? v.doubleValue() : null);
                gateway.setAverageLinkMarginDb(
                        g.get("averageLinkMarginDb") instanceof Number v ? v.doubleValue() : null);
                if (g.get("shadowedAssetKeys") instanceof List<?> keys) {
                    gateway.setShadowedAssetKeys(keys.stream().map(String::valueOf).toList());
                }
                if (g.get("coverageRadiusMeters") instanceof Number r && r.doubleValue() > 0) {
                    gateway.setCoverageRadiusMeters(r.doubleValue());
                }
                break;
            }
        }
    }

    private void applyScenarioCoverageRadius(Scenario scenario) {
        if (scenario.getCoverageRadiusMeters() == null || scenario.getSelectedGateways() == null) {
            return;
        }
        for (ScenarioSelectedGateway gateway : scenario.getSelectedGateways()) {
            if (gateway.getCoverageRadiusMeters() <= 0) {
                gateway.setCoverageRadiusMeters(scenario.getCoverageRadiusMeters());
            }
        }
    }

    private List<ScenarioSelectedGateway> loadSelectedGateways(Long scenarioId) {
        try {
            return jdbcTemplate.query(SELECT_GATEWAYS_BY_SCENARIO, (rs, rowNum) -> {
                Long candidateId = rs.getLong("candidato_gateway_id");
                double lat = rs.getDouble("lat");
                double lon = rs.getDouble("lon");
                boolean manuallyAdjusted = rs.getBoolean("ajustado_manualmente");
                return ScenarioSelectedGateway.builder()
                        .candidateId(candidateId)
                        .coordinate(new com.backend.tecsys.radio.model.RfCoordinate(lat, lon))
                        .manuallyAdjusted(manuallyAdjusted)
                        .build();
            }, scenarioId);
        } catch (Exception e) {
            return java.util.Collections.emptyList();
        }
    }

    private static final List<String> BDGD_ASSET_TABLES =
            List.of("poste", "sub", "ucbt", "ucmt", "ssdbt", "ssdmt", "ssdat");

    @Override
    public List<ScenarioAssetLocation> findAssetLocations(Long scenarioId) {
        try {
            List<String> tables = BDGD_ASSET_TABLES.stream()
                    .filter(table -> Boolean.TRUE.equals(jdbcTemplate.queryForObject(
                            "SELECT EXISTS (SELECT 1 FROM information_schema.tables "
                                    + "WHERE table_schema = 'bdgd' AND table_name = ?)",
                            Boolean.class, table)))
                    .toList();
            if (tables.isEmpty()) {
                return List.of();
            }
            String union = tables.stream()
                    .map(table -> "SELECT asset_key, tipo_ativo, geometry FROM bdgd." + table)
                    .collect(java.util.stream.Collectors.joining(" UNION ALL "));
            String sql = "SELECT c.ativo_key, c.coberto, g.candidato_gateway_id, a.tipo_ativo, "
                    + "ST_Y(ST_Centroid(a.geometry)) AS lat, ST_X(ST_Centroid(a.geometry)) AS lon "
                    + "FROM app.cenario_cobertura_ativo c "
                    + "JOIN (" + union + ") a ON a.asset_key = c.ativo_key "
                    + "LEFT JOIN app.cenario_gateway_selecionado g ON g.id = c.gateway_selecionado_id "
                    + "WHERE c.cenario_id = ?";
            return jdbcTemplate.query(sql, (rs, rowNum) -> new ScenarioAssetLocation(
                    rs.getString("ativo_key"),
                    rs.getString("tipo_ativo"),
                    rs.getDouble("lat"),
                    rs.getDouble("lon"),
                    rs.getBoolean("coberto"),
                    rs.getObject("candidato_gateway_id") != null ? rs.getLong("candidato_gateway_id") : null),
                    scenarioId);
        } catch (Exception e) {
            return List.of();
        }
    }

    private List<ScenarioAssetCoverage> loadAssetCoverages(Long scenarioId) {
        try {
            return jdbcTemplate.query(SELECT_COVERAGES_BY_SCENARIO, (rs, rowNum) -> {
                ScenarioAssetCoverage c = new ScenarioAssetCoverage();
                c.setAssetKey(rs.getString("ativo_key"));
                c.setCovered(rs.getBoolean("coberto"));
                c.setSelectedGatewayId(rs.getObject("gateway_selecionado_id") != null ? rs.getLong("gateway_selecionado_id") : null);
                return c;
            }, scenarioId);
        } catch (Exception e) {
            return java.util.Collections.emptyList();
        }
    }

    private Map<String, Double> parseJsonMap(String json) {
        try {
            return objectMapper.readValue(json != null ? json : "{}", new com.fasterxml.jackson.core.type.TypeReference<Map<String, Double>>() {});
        } catch (Exception e) {
            return new java.util.HashMap<>();
        }
    }

    /**
     * app.cenario.distribuidora_id e obrigatorio e referencia app.distribuidora. Se a tabela estiver
     * vazia (base recem-criada ou limpa), cria uma distribuidora padrao para o cenario poder ser salvo.
     */
    private void ensureDefaultUtilityExists() {
        jdbcTemplate.update(
                "INSERT INTO app.distribuidora (nome, sigla) "
                        + "SELECT 'Distribuidora Padrao', 'PADRAO' "
                        + "WHERE NOT EXISTS (SELECT 1 FROM app.distribuidora)");
    }

    private Long insertScenario(Scenario scenario) {
        ensureDefaultUtilityExists();
        KeyHolder keyHolder = new GeneratedKeyHolder();

        jdbcTemplate.update(connection -> {
            PreparedStatement statement = connection.prepareStatement(INSERT_SCENARIO, new String[]{"id"});
            statement.setString(1, scenario.getName());
            statement.setLong(2, scenario.getUserId());
            // Usuario sem distribuidora (null): o COALESCE do SQL usa a primeira distribuidora cadastrada.
            if (scenario.getUtilityId() != null) {
                statement.setLong(3, scenario.getUtilityId());
            } else {
                statement.setNull(3, Types.BIGINT);
            }
            statement.setString(4, scenario.getRegionName());
            statement.setString(5, buildAreaWkt(scenario));
            statement.setBigDecimal(6, BigDecimal.valueOf(scenario.getCoverageTargetPct()));
            statement.setInt(7, scenario.getMaxGateways());
            if (scenario.getGatewayUnitCost() != null) {
                statement.setBigDecimal(8, BigDecimal.valueOf(scenario.getGatewayUnitCost()));
            } else {
                statement.setNull(8, Types.NUMERIC);
            }
            if (scenario.getRfParameterId() != null) {
                statement.setLong(9, scenario.getRfParameterId());
            } else {
                statement.setNull(9, Types.BIGINT);
            }
            statement.setString(10, scenario.getStatus());
            if (scenario.getProcessingTimeMs() != null) {
                statement.setInt(11, scenario.getProcessingTimeMs());
            } else {
                statement.setNull(11, Types.INTEGER);
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

        // Grava a cobertura de TODOS os ativos avaliados: e ela que permite reabrir o resultado completo
        // pelo historico. (Antes havia um corte em 500, que fazia o historico mostrar so os 500 primeiros.)
        jdbcTemplate.batchUpdate(INSERT_ASSET_COVERAGE, assetCoverages, 1000, (statement, coverage) -> {
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

    private String buildAreaWkt(Scenario scenario) {
        if (scenario.getAreaWkt() != null && !scenario.getAreaWkt().isBlank()) {
            return scenario.getAreaWkt();
        }
        return buildAreaWkt(scenario.getSelectedGateways());
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
