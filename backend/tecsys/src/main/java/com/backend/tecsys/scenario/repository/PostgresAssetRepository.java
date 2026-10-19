package com.backend.tecsys.scenario.repository;

import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.scenario.exception.ScenarioPersistenceException;
import com.backend.tecsys.scenario.model.Asset;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@Repository
@Profile("!mock")
public class PostgresAssetRepository implements IAssetRepository {

    private static final List<String> KNOWN_TABLES = List.of(
            "poste", "sub", "ucbt", "ucmt", "ssdbt", "ssdmt", "ssdat"
    );

    private static final double METERS_PER_DEGREE_LATITUDE = 111_320.0;
    private static final double ENVELOPE_SAFETY_FACTOR = 1.05;

    private final JdbcTemplate jdbcTemplate;

    private final RowMapper<Asset> assetRowMapper = (rs, rowNum) -> {
        String key = null;
        try {
            key = rs.getString("asset_key");
        } catch (Exception ignored) {
        }
        if (key == null) {
            try {
                key = rs.getString("ativo_key");
            } catch (Exception ignored) {
            }
        }
        return Asset.builder()
                .assetKey(key)
                .assetType(rs.getString("tipo_ativo"))
                .coordinate(new RfCoordinate(rs.getDouble("latitude"), rs.getDouble("longitude")))
                .build();
    };

    public PostgresAssetRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private List<String> getExistingAssetTables() {
        try {
            List<String> tables = jdbcTemplate.queryForList(
                    "SELECT table_name FROM information_schema.tables WHERE table_schema = 'bdgd'",
                    String.class
            );
            return KNOWN_TABLES.stream()
                    .filter(known -> tables.stream().anyMatch(t -> t.equalsIgnoreCase(known)))
                    .toList();
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    private List<String> existingAssetTables() {
        return getExistingAssetTables();
    }

    @Override
    public List<Asset> findByUtilityId(Long utilityId) {
        List<String> tables = getExistingAssetTables();
        if (tables.isEmpty()) {
            return Collections.emptyList();
        }

        try {
            StringBuilder sql = new StringBuilder();
            List<Object> params = new ArrayList<>();
            for (int i = 0; i < tables.size(); i++) {
                if (i > 0) {
                    sql.append(" UNION ALL ");
                }
                sql.append(String.format("""
                        SELECT asset_key, asset_key AS ativo_key, tipo_ativo,
                               ST_Y(ST_Centroid(geometry)) AS latitude, ST_X(ST_Centroid(geometry)) AS longitude
                        FROM bdgd.%s
                        WHERE (CAST(? AS text) IS NULL OR distribuidora = CAST(? AS text))
                        """, tables.get(i)));
                String distStr = utilityId == null ? null : String.valueOf(utilityId);
                params.add(distStr);
                params.add(distStr);
            }
            sql.append(" ORDER BY asset_key");
            return jdbcTemplate.query(sql.toString(), assetRowMapper, params.toArray());
        } catch (Exception e) {
            throw new ScenarioPersistenceException(
                    "Falha ao obter os ativos da distribuidora " + utilityId + ".", e);
        }
    }

    @Override
    public List<Asset> findWithinRadius(double latitude, double longitude, double radiusMeters) {
        List<String> tables = getExistingAssetTables();
        if (tables.isEmpty()) {
            return Collections.emptyList();
        }

        try {
            return jdbcTemplate.query(buildRadiusQuery(false), assetRowMapper,
                    radiusParameters(longitude, latitude, radiusMeters, false));
        } catch (Exception e) {
            throw new ScenarioPersistenceException(
                    "Falha ao obter os ativos no raio especificado.", e);
        }
    }

    private String buildRadiusQuery(boolean withEnvelope) {
        List<String> tables = getExistingAssetTables();
        if (tables.isEmpty()) {
            return "SELECT NULL::text AS asset_key, NULL::text AS ativo_key, NULL::text AS tipo_ativo, "
                    + "NULL::double precision AS latitude, NULL::double precision AS longitude WHERE FALSE";
        }

        String union = tables.stream()
                .map(table -> "SELECT asset_key, asset_key AS ativo_key, tipo_ativo, geometry "
                        + "FROM bdgd." + table
                        + " WHERE " + (withEnvelope
                        ? "geometry && ST_MakeEnvelope(?, ?, ?, ?, 4326) AND " : "")
                        + "ST_DWithin(geometry::geography, "
                        + "ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)")
                .collect(java.util.stream.Collectors.joining(" UNION ALL "));
        return "SELECT asset_key, ativo_key, tipo_ativo, ST_Y(ST_Centroid(geometry)) AS latitude, "
                + "ST_X(ST_Centroid(geometry)) AS longitude FROM (" + union + ") assets "
                + "ORDER BY asset_key" + (withEnvelope ? "" : " LIMIT 5000");
    }

    private Object[] radiusParameters(
            double longitude, double latitude, double radiusMeters, boolean withEnvelope) {
        List<Object> parameters = new java.util.ArrayList<>();
        int count = getExistingAssetTables().size();
        for (int ignored = 0; ignored < count; ignored++) {
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

    @Override
    public List<Asset> findAllWithinRadius(double latitude, double longitude, double radiusMeters) {
        List<String> tables = getExistingAssetTables();
        if (tables.isEmpty()) {
            return Collections.emptyList();
        }

        try {
            return jdbcTemplate.query(
                    buildRadiusQuery(true),
                    assetRowMapper,
                    radiusParameters(longitude, latitude, radiusMeters, true));
        } catch (Exception e) {
            throw new ScenarioPersistenceException(
                    "Falha ao obter os ativos da area de busca.", e);
        }
    }

    private String selectAssetsSql(String unionSql) {
        return "SELECT asset_key, tipo_ativo, ST_Y(ST_Centroid(geometry)) AS latitude, "
                + "ST_X(ST_Centroid(geometry)) AS longitude FROM (" + unionSql + ") assets";
    }

    private String wrapWithRadiusFilter(String unionSql) {
        return "SELECT asset_key, tipo_ativo, latitude, longitude FROM (" + selectAssetsSql(unionSql)
                + ") assets WHERE ST_DWithin("
                + "ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography, "
                + "ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?) "
                + "ORDER BY asset_key LIMIT 5000";
    }

    private String wrapWithEnvelopeAndRadiusFilter(String unionSql) {
        return "SELECT asset_key, tipo_ativo, latitude, longitude FROM (" + selectAssetsSql(unionSql)
                + ") assets WHERE ST_MakePoint(longitude, latitude) && ST_MakeEnvelope(?, ?, ?, ?, 4326) "
                + "AND ST_DWithin("
                + "ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography, "
                + "ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?) "
                + "ORDER BY asset_key";
    }
}
