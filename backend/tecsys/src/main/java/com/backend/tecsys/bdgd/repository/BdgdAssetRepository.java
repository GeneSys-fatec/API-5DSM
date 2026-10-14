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
        // Captura snapshot local para evitar race condition com tableExists() que
        // pode zerar cachedTables fora do bloco synchronized.
        java.util.Set<String> snapshot = cachedTables;
        if (snapshot == null) {
            synchronized (this) {
                snapshot = cachedTables;
                if (snapshot == null) {
                    try {
                        snapshot = new java.util.HashSet<>(jdbc.queryForList(
                            "SELECT table_name FROM information_schema.tables WHERE table_schema = 'bdgd'",
                            String.class
                        ));
                    } catch (Exception e) {
                        snapshot = java.util.Collections.emptySet();
                    }
                    cachedTables = snapshot;
                }
            }
        }
        return snapshot;
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

        List<String> queries = new java.util.ArrayList<>();
        List<Object> parameters = new java.util.ArrayList<>();
        for (String table : existingTables) {
            java.util.Set<String> columns = new java.util.HashSet<>(jdbc.queryForList(
                    "SELECT column_name FROM information_schema.columns "
                            + "WHERE table_schema = 'bdgd' AND table_name = ?",
                    String.class, table));
            List<String> predicates = new java.util.ArrayList<>();
            if (columns.contains("importacao_id")) {
                predicates.add("importacao_id = ?");
                parameters.add(importId.toString());
            }
            String keyColumn = columns.contains("asset_key")
                    ? "asset_key"
                    : columns.contains("ativo_key") ? "ativo_key" : null;
            if (keyColumn != null) {
                predicates.add(keyColumn + " LIKE ?");
                parameters.add("%::" + importId + "::%");
            }
            if (!predicates.isEmpty()) {
                queries.add("SELECT COUNT(*) AS asset_count FROM bdgd." + table
                        + " WHERE " + String.join(" OR ", predicates));
            }
        }
        if (queries.isEmpty()) {
            return 0;
        }
        try {
            Integer total = jdbc.queryForObject(
                    "SELECT COALESCE(SUM(asset_count), 0) FROM ("
                            + String.join(" UNION ALL ", queries) + ") counts",
                Integer.class, parameters.toArray());
            return total == null ? 0 : total;
        } catch (org.springframework.jdbc.BadSqlGrammarException ignored) {
            // Tabelas criadas antes do vínculo por importação não têm dados confiáveis para este card.
            return 0;
        }
    }

    public Map<String, Integer> countAssetsGroupedByImportId(List<String> tableNames) {
    Map<String, Integer> out = new java.util.HashMap<>();
    for (String table : tableNames) {
        String t = table.toLowerCase();
        if (!tableExists(t)) {
            continue;
        }
        try {
            jdbc.query(
                    "SELECT importacao_id, COUNT(*) FROM bdgd." + t
                            + " WHERE importacao_id IS NOT NULL GROUP BY importacao_id",
                    (org.springframework.jdbc.core.RowCallbackHandler) rs ->
                            out.merge(rs.getString(1), (int) rs.getLong(2), Integer::sum));
        } catch (org.springframework.jdbc.BadSqlGrammarException ignored) {
            // tabela sem coluna importacao_id (criada antes do vinculo por importacao)
        }
    }
    return out;
}

    public String getCrsByImportId(UUID id, List<String> tables) {
        for (String t : tables) {
            if (!tableExists(t.toLowerCase())) continue;
            try {
                var res = jdbc.queryForList(
                        "SELECT ST_X(geometry) as lon, ST_Y(geometry) as lat FROM bdgd." + t
                                + " WHERE importacao_id=? AND geometry IS NOT NULL LIMIT 1",
                        id.toString());
                if (!res.isEmpty()) {
                    double lon = ((Number) res.get(0).get("lon")).doubleValue();
                    double lat = ((Number) res.get(0).get("lat")).doubleValue();
                    return "SIRGAS 2000 / UTM " + ((int) Math.floor((lon + 180) / 6) + 1) + (lat < 0 ? "S" : "N");
                }
            } catch (Exception ignored) {}
        }
        return "SIRGAS 2000 / UTM N/A";
    }

    /**
     * Calcula o CRS UTM SIRGAS 2000 de todos os imports em batch.
     * Faz no máximo uma query por tabela (em vez de N queries por import),
     * retornando Map&lt;importacaoId, crs&gt;.
     */
    public Map<String, String> getCrsMapByAllImports(List<String> tables) {
        Map<String, String> result = new java.util.HashMap<>();
        for (String t : tables) {
            if (!tableExists(t.toLowerCase())) continue;
            try {
                jdbc.query(
                    "SELECT importacao_id, ST_X(geometry) AS lon, ST_Y(geometry) AS lat "
                    + "FROM bdgd." + t.toLowerCase()
                    + " WHERE importacao_id IS NOT NULL AND geometry IS NOT NULL",
                    (org.springframework.jdbc.core.RowCallbackHandler) rs -> {
                        String importId = rs.getString("importacao_id");
                        if (importId != null && !result.containsKey(importId)) {
                            double lon = rs.getDouble("lon");
                            double lat = rs.getDouble("lat");
                            result.put(importId,
                                "SIRGAS 2000 / UTM " + ((int) Math.floor((lon + 180) / 6) + 1) + (lat < 0 ? "S" : "N"));
                        }
                    });
            } catch (Exception ignored) {}
        }
        return result;
    }

    private boolean tableExists(String tableName) {
        String t = tableName.toLowerCase();
        if (getExistingTables().contains(t)) {
            return true;
        }
        // Cache miss: invalida sob synchronized e recarrega uma vez.
        synchronized (this) {
            cachedTables = null;
        }
        return getExistingTables().contains(t);
    }
}
