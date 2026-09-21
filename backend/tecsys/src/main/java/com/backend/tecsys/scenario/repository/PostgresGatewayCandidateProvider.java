package com.backend.tecsys.scenario.repository;

import com.backend.tecsys.scenario.exception.ScenarioPersistenceException;
import com.backend.tecsys.scenario.model.GatewayCandidate;
import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.scenario.repository.GatewayCandidateProvider;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Profile("!mock")
public class PostgresGatewayCandidateProvider implements GatewayCandidateProvider {

    private static final String SELECT_CANDIDATES = """
            SELECT id, origem, ativo_key, custo_estimado,
                   ST_Y(geom) AS latitude, ST_X(geom) AS longitude
            FROM app.candidato_gateway
            WHERE distribuidora_id = ?
            ORDER BY id
            """;

    private final JdbcTemplate jdbcTemplate;

    private final RowMapper<GatewayCandidate> candidateRowMapper = (rs, rowNum) -> GatewayCandidate.builder()
            .id(rs.getLong("id"))
            .source(rs.getString("origem"))
            .assetKey(rs.getString("ativo_key"))
            .coordinate(new RfCoordinate(rs.getDouble("latitude"), rs.getDouble("longitude")))
            .estimatedCost(rs.getObject("custo_estimado") != null ? rs.getDouble("custo_estimado") : null)
            .build();

    public PostgresGatewayCandidateProvider(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public List<GatewayCandidate> getCandidates(Long utilityId) {
        try {
            return jdbcTemplate.query(SELECT_CANDIDATES, candidateRowMapper, utilityId);
        } catch (Exception e) {
            throw new ScenarioPersistenceException(
                    "Falha ao obter os candidatos a gateway da distribuidora " + utilityId + ".", e);
        }
    }
}
