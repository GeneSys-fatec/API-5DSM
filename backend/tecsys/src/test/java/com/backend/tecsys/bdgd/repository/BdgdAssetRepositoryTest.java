package com.backend.tecsys.bdgd.repository;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class BdgdAssetRepositoryTest {
    @Test
    void countsAssetsByImportIdInsteadOfReturningOneSharedCount() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        when(jdbc.queryForList(anyString(), eq(String.class))).thenReturn(List.of("poste"));

        UUID firstImport = UUID.randomUUID();
        UUID secondImport = UUID.randomUUID();
        when(jdbc.queryForObject(anyString(), eq(Integer.class), eq(firstImport.toString())))
                .thenReturn(45_909);
        when(jdbc.queryForObject(anyString(), eq(Integer.class), eq(secondImport.toString())))
                .thenReturn(5_258);

        BdgdAssetRepository repository = new BdgdAssetRepository(jdbc);

        int firstCount = repository.countAssetsByImportId(firstImport, List.of("poste"));
        int secondCount = repository.countAssetsByImportId(secondImport, List.of("poste"));

        assertEquals(45_909, firstCount);
        assertEquals(5_258, secondCount);
        assertNotEquals(firstCount, secondCount);
    }

    @Test
    void computesBoundaryHullOnlyOnceAndRecomputesAfterEviction() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        when(jdbc.queryForList(anyString(), eq(String.class))).thenReturn(List.of("poste"));
        when(jdbc.queryForMap(anyString(), any(Object[].class)))
                .thenReturn(Map.of("asset_count", 10L, "hull_geojson", "{\"type\":\"Polygon\",\"coordinates\":[]}"));
        when(jdbc.queryForObject(anyString(), eq(Boolean.class), any(Object[].class))).thenReturn(true);

        BdgdAssetRepository repository = new BdgdAssetRepository(jdbc);

        Map<String, Object> first = repository.findConvexHullContainsPoint("TESTE", "TESTE", -37.0, -10.9);
        Map<String, Object> second = repository.findConvexHullContainsPoint("TESTE", "TESTE", -37.1, -10.8);
        repository.findConvexHullByDistribuidora("TESTE", "TESTE");

        assertEquals(10, first.get("asset_count"));
        assertEquals(true, second.get("point_contained"));
        // O contorno (varredura da base inteira) so e calculado na primeira chamada.
        verify(jdbc, times(1)).queryForMap(anyString(), any(Object[].class));

        repository.evictCountCache();
        repository.findConvexHullByDistribuidora("TESTE", "TESTE");
        verify(jdbc, times(2)).queryForMap(anyString(), any(Object[].class));
    }
}