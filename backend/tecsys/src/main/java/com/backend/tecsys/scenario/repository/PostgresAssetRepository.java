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

    private final RowMapper<Asset> assetRowMapper = (rs, rowNum) -> Asset.builder()
            .assetKey(rs.getString("asset_key"))
            .assetType(rs.getString("tipo_ativo"))
            .coordinate(new RfCoordinate(rs.getDouble("latitude"), rs.getDouble("longitude")))
            .build();

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
                        SELECT asset_key, tipo_ativo,
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
            StringBuilder sql = new StringBuilder();
            List<Object> params = new ArrayList<>();
            for (int i = 0; i < tables.size(); i++) {
                if (i > 0) {
                    sql.append(" UNION ALL ");
                }
                sql.append(String.format("""
                        SELECT asset_key, tipo_ativo,
                               ST_Y(ST_Centroid(geometry)) AS latitude, ST_X(ST_Centroid(geometry)) AS longitude
                        FROM bdgd.%s
                        WHERE ST_DWithin(geometry::geography, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)
                        """, tables.get(i)));
                params.add(longitude);
                params.add(latitude);
                params.add(radiusMeters);
            }
            sql.append(" ORDER BY asset_key LIMIT 5000");
            return jdbcTemplate.query(sql.toString(), assetRowMapper, params.toArray());
        } catch (Exception e) {
            throw new ScenarioPersistenceException(
                    "Falha ao obter os ativos no raio especificado.", e);
        }
    }

    @Override
    public List<Asset> findAllWithinRadius(double latitude, double longitude, double radiusMeters) {
        List<String> tables = getExistingAssetTables();
        if (tables.isEmpty()) {
            return Collections.emptyList();
        }

        double deltaLatitude = radiusMeters / METERS_PER_DEGREE_LATITUDE * ENVELOPE_SAFETY_FACTOR;
        double metersPerDegreeLongitude = METERS_PER_DEGREE_LATITUDE * Math.cos(Math.toRadians(latitude));
        double deltaLongitude = metersPerDegreeLongitude <= 0
                ? 180.0
                : radiusMeters / metersPerDegreeLongitude * ENVELOPE_SAFETY_FACTOR;

        double minLon = longitude - deltaLongitude;
        double minLat = latitude - deltaLatitude;
        double maxLon = longitude + deltaLongitude;
        double maxLat = latitude + deltaLatitude;

        try {
            StringBuilder sql = new StringBuilder();
            List<Object> params = new ArrayList<>();
            for (int i = 0; i < tables.size(); i++) {
                if (i > 0) {
                    sql.append(" UNION ALL ");
                }
                sql.append(String.format("""
                        SELECT asset_key, tipo_ativo,
                               ST_Y(ST_Centroid(geometry)) AS latitude, ST_X(ST_Centroid(geometry)) AS longitude
                        FROM bdgd.%s
                        WHERE geometry && ST_MakeEnvelope(?, ?, ?, ?, 4326)
                          AND ST_DWithin(geometry::geography, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)
                        """, tables.get(i)));
                params.add(minLon);
                params.add(minLat);
                params.add(maxLon);
                params.add(maxLat);
                params.add(longitude);
                params.add(latitude);
                params.add(radiusMeters);
            }
            sql.append(" ORDER BY asset_key");
            return jdbcTemplate.query(sql.toString(), assetRowMapper, params.toArray());
        } catch (Exception e) {
            throw new ScenarioPersistenceException(
                    "Falha ao obter os ativos da área de busca.", e);
        }
    }
}
