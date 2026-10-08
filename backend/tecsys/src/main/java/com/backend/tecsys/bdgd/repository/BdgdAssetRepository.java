package com.backend.tecsys.bdgd.repository;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;
import java.util.UUID;

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
                WHERE (CAST(? AS text) IS NULL OR distribuidora = CAST(? AS text))
                  AND (CAST(? AS text) IS NULL OR regiao = CAST(? AS text))
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

    private final Map<String, Integer> countCache = new java.util.concurrent.ConcurrentHashMap<>();
    private volatile java.util.Set<String> cachedTables = null;

    private java.util.Set<String> getExistingTables() {
        if (cachedTables == null) {
            synchronized (this) {
                if (cachedTables == null) {
                    try {
                        cachedTables = new java.util.HashSet<>(jdbc.queryForList(
                            "SELECT table_name FROM information_schema.tables WHERE table_schema = 'bdgd'",
                            String.class
                        ));
                    } catch (Exception e) {
                        cachedTables = java.util.Collections.emptySet();
                    }
                }
            }
        }
        return cachedTables;
    }

    public int countAssetsByDistribuidora(String distribuidora, List<String> tableNames) {
        String cacheKey = distribuidora == null ? "__ALL__" : distribuidora.toLowerCase().trim();
        if (countCache.containsKey(cacheKey)) {
            return countCache.get(cacheKey);
        }

        int total = 0;
        try {
            Integer ativoCount = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM bdgd.ativo WHERE (CAST(? AS text) IS NULL OR ativo_key ILIKE CAST(? AS text))",
                    Integer.class,
                    distribuidora, "%" + distribuidora + "%");
            if (ativoCount != null && ativoCount > 0) {
                total = ativoCount;
            }
        } catch (Exception ignored) {
        }

        if (total == 0) {
            java.util.Set<String> existing = getExistingTables();
            for (String tableName : tableNames) {
                if (existing.contains(tableName.toLowerCase())) {
                    try {
                        Integer count = jdbc.queryForObject(
                                "SELECT COUNT(*) FROM bdgd." + tableName + " WHERE (CAST(? AS text) IS NULL OR distribuidora = CAST(? AS text))",
                                Integer.class,
                                distribuidora, distribuidora);
                        if (count != null) {
                            total += count;
                        }
                    } catch (Exception ignored) {
                    }
                }
            }
        }

        countCache.put(cacheKey, total);
        return total;
    }

    public int countAssetsByImportId(UUID importId, List<String> tableNames) {
        List<String> existingTables = tableNames.stream()
                .map(String::toLowerCase)
                .filter(getExistingTables()::contains)
                .toList();
        if (existingTables.isEmpty()) {
            return 0;
        }

        String union = existingTables.stream()
                .map(table -> "SELECT COUNT(*) AS asset_count FROM bdgd." + table + " WHERE importacao_id = ?")
                .collect(java.util.stream.Collectors.joining(" UNION ALL "));
        Object[] parameters = java.util.Collections.nCopies(existingTables.size(), importId.toString()).toArray();
        try {
            Integer total = jdbc.queryForObject(
                    "SELECT COALESCE(SUM(asset_count), 0) FROM (" + union + ") counts",
                    Integer.class, parameters);
            return total == null ? 0 : total;
        } catch (org.springframework.jdbc.BadSqlGrammarException ignored) {
            // Tabelas criadas antes do vínculo por importação não têm dados confiáveis para este card.
            return 0;
        }
    }

    private boolean tableExists(String tableName) {
        return getExistingTables().contains(tableName.toLowerCase());
    }
}
