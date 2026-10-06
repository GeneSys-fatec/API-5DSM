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

    private static final String SELECT_ASSETS_WITHIN_RADIUS = """
            SELECT ativo_key, tipo_ativo,
                   ST_Y(ST_Centroid(geom)) AS latitude, ST_X(ST_Centroid(geom)) AS longitude
            FROM bdgd.ativo
            WHERE ST_DWithin(geom::geography, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)
            ORDER BY ativo_key
            LIMIT 5000
            """;

    private static final String SELECT_ALL_ASSETS_WITHIN_RADIUS = """
            SELECT ativo_key, tipo_ativo,
                   ST_Y(ST_Centroid(geom)) AS latitude, ST_X(ST_Centroid(geom)) AS longitude
            FROM bdgd.ativo
            WHERE geom && ST_MakeEnvelope(?, ?, ?, ?, 4326)
              AND ST_DWithin(geom::geography, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)
            ORDER BY ativo_key
            """;

    private static final double METERS_PER_DEGREE_LATITUDE = 111_320.0;
    private static final double ENVELOPE_SAFETY_FACTOR = 1.05;

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

    @Override
    public List<Asset> findWithinRadius(double latitude, double longitude, double radiusMeters) {
        try {
            return jdbcTemplate.query(SELECT_ASSETS_WITHIN_RADIUS, assetRowMapper, longitude, latitude, radiusMeters);
        } catch (Exception e) {
            throw new ScenarioPersistenceException(
                    "Falha ao obter os ativos no raio especificado.", e);
        }
    }

    @Override
    public List<Asset> findAllWithinRadius(double latitude, double longitude, double radiusMeters) {
        double deltaLatitude = radiusMeters / METERS_PER_DEGREE_LATITUDE * ENVELOPE_SAFETY_FACTOR;
        double metersPerDegreeLongitude = METERS_PER_DEGREE_LATITUDE * Math.cos(Math.toRadians(latitude));
        double deltaLongitude = metersPerDegreeLongitude <= 0
                ? 180.0
                : radiusMeters / metersPerDegreeLongitude * ENVELOPE_SAFETY_FACTOR;

        try {
            return jdbcTemplate.query(
                    SELECT_ALL_ASSETS_WITHIN_RADIUS,
                    assetRowMapper,
                    longitude - deltaLongitude, latitude - deltaLatitude,
                    longitude + deltaLongitude, latitude + deltaLatitude,
                    longitude, latitude, radiusMeters);
        } catch (Exception e) {
            throw new ScenarioPersistenceException(
                    "Falha ao obter os ativos da área de busca.", e);
        }
    }
}
