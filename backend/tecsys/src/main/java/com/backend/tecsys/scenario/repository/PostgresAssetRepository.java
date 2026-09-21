package com.backend.tecsys.scenario.repository;

import com.backend.tecsys.scenario.exception.ScenarioPersistenceException;
import com.backend.tecsys.scenario.model.Asset;
import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.scenario.repository.IAssetRepository;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Profile("!mock")
public class PostgresAssetRepository implements IAssetRepository {

    private static final String SELECT_ASSETS = """
            SELECT ativo_key, tipo_ativo,
                   ST_Y(ST_Centroid(geom)) AS latitude, ST_X(ST_Centroid(geom)) AS longitude
            FROM bdgd.ativo
            WHERE distribuidora_id = ?
            ORDER BY ativo_key
            """;

    private final JdbcTemplate jdbcTemplate;

    private final RowMapper<Asset> assetRowMapper = (rs, rowNum) -> Asset.builder()
            .assetKey(rs.getString("ativo_key"))
            .assetType(rs.getString("tipo_ativo"))
            .coordinate(new RfCoordinate(rs.getDouble("latitude"), rs.getDouble("longitude")))
            .build();

    public PostgresAssetRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public List<Asset> findByUtilityId(Long utilityId) {
        try {
            return jdbcTemplate.query(SELECT_ASSETS, assetRowMapper, utilityId);
        } catch (Exception e) {
            throw new ScenarioPersistenceException(
                    "Falha ao obter os ativos da distribuidora " + utilityId + ".", e);
        }
    }
}
