package com.backend.tecsys.bdgd.repository;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class BdgdAssetRepository {

    public static final List<String> ASSET_TABLES = List.of(
            "poste", "sub", "ucbt", "ucmt", "ssdbt", "ssdmt", "ssdat");

    private static final Duration COUNT_CACHE_TTL = Duration.ofSeconds(30);
    private static final int MAX_COUNT_CACHE_ENTRIES = 256;

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

    public Map<String, Object> findConvexHullByDistribuidora(String distribuidora, String regiao) {
        AssetUnionQuery query = buildAssetUnionQuery(distribuidora, regiao);
        if (query == null) {
            Map<String, Object> empty = new java.util.HashMap<>();
            empty.put("asset_count", 0);
            empty.put("hull_geojson", null);
            return empty;
        }

        String sql = """
                SELECT COUNT(*) AS asset_count,
                       ST_AsGeoJSON(ST_ConvexHull(ST_Collect(geometry))) AS hull_geojson
                FROM (%s) AS assets
                """.formatted(query.sql());

        return jdbc.queryForMap(sql, query.params());
    }

    public Map<String, Object> findConvexHullContainsPoint(
            String distribuidora, String regiao, double longitude, double latitude) {
        AssetUnionQuery query = buildAssetUnionQuery(distribuidora, regiao);
        if (query == null) {
            Map<String, Object> empty = new java.util.HashMap<>();
            empty.put("asset_count", 0);
            empty.put("hull_geojson", null);
            empty.put("point_contained", null);
            return empty;
        }

        String sql = """
                WITH hull AS (
                    SELECT ST_ConvexHull(ST_Collect(geometry)) AS geom, COUNT(*) AS asset_count
                    FROM (%s) AS assets
                )
                SELECT asset_count,
                       ST_AsGeoJSON(geom) AS hull_geojson,
                       CASE WHEN ST_GeometryType(geom) = 'ST_Polygon'
                            THEN ST_Contains(geom, ST_SetSRID(ST_MakePoint(?, ?), 4326))
                            ELSE NULL END AS point_contained
                FROM hull
                """.formatted(query.sql());

        List<Object> params = new java.util.ArrayList<>(java.util.Arrays.asList(query.params()));
        params.add(longitude);
        params.add(latitude);

        return jdbc.queryForMap(sql, params.toArray());
    }

    public AssetUnionQuery buildAssetUnionQuery(String distribuidora, String regiao) {
        List<String> existingTables = existingAssetTables();
        if (existingTables.isEmpty()) {
            return null;
        }

        String sql = existingTables.stream()
                .map(table -> "SELECT asset_key, tipo_ativo, geometry FROM bdgd.%s WHERE distribuidora = ? AND regiao = ?".formatted(table))
                .reduce((a, b) -> a + " UNION ALL " + b)
                .orElseThrow();

        Object[] params = existingTables.stream()
                .flatMap(table -> java.util.stream.Stream.of((Object) distribuidora, regiao))
                .toArray();

        return new AssetUnionQuery(sql, params);
    }

    public List<String> existingAssetTables() {
        return ASSET_TABLES.stream().filter(this::tableExists).toList();
    }

    public record AssetUnionQuery(String sql, Object[] params) {
    }

    private record CachedCount(int quantidade, Instant calculadoEm) {
        boolean expirado() {
            return Duration.between(calculadoEm, Instant.now()).compareTo(COUNT_CACHE_TTL) >= 0;
        }
    }

    private final Map<String, CachedCount> countCache = new java.util.concurrent.ConcurrentHashMap<>();
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
        String cacheKey = distribuidora == null ? "" : distribuidora.trim();
        CachedCount cached = countCache.get(cacheKey);
        if (cached != null && !cached.expirado()) {
            return cached.quantidade();
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

        cacheCount(cacheKey, total);
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

    private void cacheCount(String cacheKey, int total) {
        if (countCache.size() >= MAX_COUNT_CACHE_ENTRIES) {
            countCache.values().removeIf(CachedCount::expirado);
            if (countCache.size() >= MAX_COUNT_CACHE_ENTRIES) {
                countCache.clear();
            }
        }
        countCache.put(cacheKey, new CachedCount(total, Instant.now()));
    }

    public void evictCountCache() {
        countCache.clear();
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
