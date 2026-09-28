package com.backend.tecsys.bdgd.repository;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
@RequiredArgsConstructor
public class BdgdAssetRepository {
    private final JdbcTemplate jdbc;

    public List<Map<String, Object>> findFeatures(
            String tableName,
            String distribuidora,
            String regiao,
            int limit,
            int offset) {
      return findFeatures(tableName, distribuidora, regiao, null, null, null, null, limit, offset);
        }

        public List<Map<String, Object>> findFeatures(
          String tableName,
          String distribuidora,
          String regiao,
          Double minLon,
          Double minLat,
          Double maxLon,
          Double maxLat,
          int limit,
          int offset) {
      boolean hasBbox = minLon != null && minLat != null && maxLon != null && maxLat != null;
        if (!tableExists(tableName)) {
          return List.of();
        }
      String bboxFilter = hasBbox
        ? "AND ST_Intersects(geometry, ST_MakeEnvelope(?, ?, ?, ?, 4326))"
        : "";
        String sql = """
                SELECT id, tipo_ativo, distribuidora, regiao, asset_key,
                       ST_AsGeoJSON(geometry) AS geometry
                FROM bdgd.%s
                WHERE (? IS NULL OR distribuidora = ?)
                  AND (? IS NULL OR regiao = ?)
          %s
                ORDER BY id
                LIMIT ? OFFSET ?
        """.formatted(tableName, bboxFilter);

      if (hasBbox) {
          return jdbc.queryForList(sql, distribuidora, distribuidora, regiao, regiao,
            minLon, minLat, maxLon, maxLat, limit, offset);
      }
      return jdbc.queryForList(sql, distribuidora, distribuidora, regiao, regiao, limit, offset);
    }

    public int countAssetsByDistribuidora(String distribuidora, List<String> tableNames) {
        int total = 0;
        for (String tableName : tableNames) {
            if (tableExists(tableName)) {
                Integer count = jdbc.queryForObject(
                        "SELECT COUNT(*) FROM bdgd." + tableName + " WHERE (? IS NULL OR LOWER(distribuidora) = LOWER(?))",
                        Integer.class,
                        distribuidora, distribuidora);
                if (count != null) {
                    total += count;
                }
            }
        }
        return total;
    }

    private boolean tableExists(String tableName) {
      return Boolean.TRUE.equals(jdbc.queryForObject(
          "SELECT EXISTS (SELECT 1 FROM information_schema.tables "
              + "WHERE table_schema = 'bdgd' AND table_name = ?)",
          Boolean.class,
          tableName));
    }
}
