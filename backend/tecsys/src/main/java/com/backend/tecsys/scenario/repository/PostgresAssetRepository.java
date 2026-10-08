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
            return jdbcTemplate.query(buildRadiusQuery(false), assetRowMapper,
                radiusParameters(longitude, latitude, radiusMeters, false));
        } catch (Exception e) {
            throw new ScenarioPersistenceException(
                    "Falha ao obter os ativos no raio especificado.", e);
        }
    }

        private String buildRadiusQuery(boolean withEnvelope) {
        List<String> tables = existingAssetTables();
        if (tables.isEmpty()) {
            return "SELECT NULL::text AS ativo_key, NULL::text AS tipo_ativo, "
                + "NULL::double precision AS latitude, NULL::double precision AS longitude WHERE FALSE";
        }

        String union = tables.stream()
            .map(table -> "SELECT asset_key AS ativo_key, tipo_ativo, geometry "
                + "FROM bdgd." + table
                + " WHERE " + (withEnvelope
                    ? "geometry && ST_MakeEnvelope(?, ?, ?, ?, 4326) AND " : "")
                + "ST_DWithin(geometry::geography, "
                + "ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)")
            .collect(java.util.stream.Collectors.joining(" UNION ALL "));
        return "SELECT ativo_key, tipo_ativo, ST_Y(ST_Centroid(geometry)) AS latitude, "
            + "ST_X(ST_Centroid(geometry)) AS longitude FROM (" + union + ") assets "
            + "ORDER BY ativo_key LIMIT 5000";
        }

        private Object[] radiusParameters(
                double longitude, double latitude, double radiusMeters, boolean withEnvelope) {
        List<Object> parameters = new java.util.ArrayList<>();
        for (int ignored = 0; ignored < existingAssetTables().size(); ignored++) {
            if (withEnvelope) {
                double deltaLatitude = radiusMeters / METERS_PER_DEGREE_LATITUDE * ENVELOPE_SAFETY_FACTOR;
                double metersPerDegreeLongitude = METERS_PER_DEGREE_LATITUDE * Math.cos(Math.toRadians(latitude));
                double deltaLongitude = metersPerDegreeLongitude <= 0
                        ? 180.0
                        : radiusMeters / metersPerDegreeLongitude * ENVELOPE_SAFETY_FACTOR;
                parameters.add(longitude - deltaLongitude);
                parameters.add(latitude - deltaLatitude);
                parameters.add(longitude + deltaLongitude);
                parameters.add(latitude + deltaLatitude);
            }
            parameters.add(longitude);
            parameters.add(latitude);
            parameters.add(radiusMeters);
        }
        return parameters.toArray();
        }

        private List<String> existingAssetTables() {
        List<String> candidates = List.of("poste", "sub", "ucbt", "ucmt", "ssdbt", "ssdmt", "ssdat");
        return candidates.stream()
            .filter(table -> Boolean.TRUE.equals(jdbcTemplate.queryForObject(
                "SELECT EXISTS (SELECT 1 FROM information_schema.tables "
                    + "WHERE table_schema = 'bdgd' AND table_name = ?)",
                Boolean.class, table)))
            .toList();
        }

    @Override
    public List<Asset> findAllWithinRadius(double latitude, double longitude, double radiusMeters) {
        try {
            return jdbcTemplate.query(
                buildRadiusQuery(true),
                    assetRowMapper,
                radiusParameters(longitude, latitude, radiusMeters, true));
        } catch (Exception e) {
            throw new ScenarioPersistenceException(
                    "Falha ao obter os ativos da área de busca.", e);
        }
    }
}
