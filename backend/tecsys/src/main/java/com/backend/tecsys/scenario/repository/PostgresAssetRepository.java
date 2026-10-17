package com.backend.tecsys.scenario.repository;

import com.backend.tecsys.bdgd.model.BdgdImportRecord;
import com.backend.tecsys.bdgd.repository.BdgdAssetRepository;
import com.backend.tecsys.bdgd.repository.BdgdImportRepository;
import com.backend.tecsys.scenario.exception.ScenarioPersistenceException;
import com.backend.tecsys.scenario.model.Asset;
import com.backend.tecsys.radio.model.RfCoordinate;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Repository
@Profile("!mock")
public class PostgresAssetRepository implements IAssetRepository {

    private static final double METERS_PER_DEGREE_LATITUDE = 111_320.0;
    private static final double ENVELOPE_SAFETY_FACTOR = 1.05;

    private final JdbcTemplate jdbcTemplate;
    private final BdgdImportRepository importRepository;
    private final BdgdAssetRepository bdgdAssetRepository;

    private final RowMapper<Asset> assetRowMapper = (rs, rowNum) -> Asset.builder()
            .assetKey(rs.getString("asset_key"))
            .assetType(rs.getString("tipo_ativo"))
            .coordinate(new RfCoordinate(rs.getDouble("latitude"), rs.getDouble("longitude")))
            .build();

    public PostgresAssetRepository(
            JdbcTemplate jdbcTemplate,
            BdgdImportRepository importRepository,
            BdgdAssetRepository bdgdAssetRepository) {
        this.jdbcTemplate = jdbcTemplate;
        this.importRepository = importRepository;
        this.bdgdAssetRepository = bdgdAssetRepository;
    }

    @Override
    public List<Asset> findByImportId(UUID importId) {
        BdgdImportRecord record = importRepository.find(importId);
        BdgdAssetRepository.AssetUnionQuery query = requireUnionQuery(record);
        try {
            return jdbcTemplate.query(selectAssetsSql(query.sql()), assetRowMapper, query.params());
        } catch (Exception e) {
            throw new ScenarioPersistenceException(
                    "Falha ao obter os ativos da importacao " + importId + ".", e);
        }
    }

    @Override
    public List<Asset> findWithinRadius(UUID importId, double latitude, double longitude, double radiusMeters) {
        BdgdImportRecord record = importRepository.find(importId);
        BdgdAssetRepository.AssetUnionQuery query = requireUnionQuery(record);
        String sql = wrapWithRadiusFilter(query.sql());

        List<Object> params = new ArrayList<>(List.of(query.params()));
        params.add(longitude);
        params.add(latitude);
        params.add(radiusMeters);

        try {
            return jdbcTemplate.query(sql, assetRowMapper, params.toArray());
        } catch (Exception e) {
            throw new ScenarioPersistenceException(
                    "Falha ao obter os ativos no raio especificado.", e);
        }
    }

    @Override
    public List<Asset> findAllWithinRadius(UUID importId, double latitude, double longitude, double radiusMeters) {
        BdgdImportRecord record = importRepository.find(importId);
        BdgdAssetRepository.AssetUnionQuery query = requireUnionQuery(record);

        double deltaLatitude = radiusMeters / METERS_PER_DEGREE_LATITUDE * ENVELOPE_SAFETY_FACTOR;
        double metersPerDegreeLongitude = METERS_PER_DEGREE_LATITUDE * Math.cos(Math.toRadians(latitude));
        double deltaLongitude = metersPerDegreeLongitude <= 0
                ? 180.0
                : radiusMeters / metersPerDegreeLongitude * ENVELOPE_SAFETY_FACTOR;

        String sql = wrapWithEnvelopeAndRadiusFilter(query.sql());

        List<Object> params = new ArrayList<>(List.of(query.params()));
        params.add(longitude - deltaLongitude);
        params.add(latitude - deltaLatitude);
        params.add(longitude + deltaLongitude);
        params.add(latitude + deltaLatitude);
        params.add(longitude);
        params.add(latitude);
        params.add(radiusMeters);

        try {
            return jdbcTemplate.query(sql, assetRowMapper, params.toArray());
        } catch (Exception e) {
            throw new ScenarioPersistenceException(
                    "Falha ao obter os ativos da area de busca.", e);
        }
    }

    private BdgdAssetRepository.AssetUnionQuery requireUnionQuery(BdgdImportRecord record) {
        BdgdAssetRepository.AssetUnionQuery query =
                bdgdAssetRepository.buildAssetUnionQuery(record.distribuidora(), record.regiao());
        if (query == null) {
            throw new ScenarioPersistenceException(
                    "Nenhuma tabela de ativo disponivel ainda para a distribuidora '"
                            + record.distribuidora() + "' / regiao '" + record.regiao()
                            + "'. O processamento ETL dessa importacao pode nao ter concluido.",
                    null);
        }
        return query;
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
