package com.backend.tecsys;

import com.backend.tecsys.bdgd.model.BdgdBoundsResponse;
import com.backend.tecsys.bdgd.model.BdgdImportRecord;
import com.backend.tecsys.bdgd.model.BdgdImportStatus;
import com.backend.tecsys.bdgd.repository.BdgdAssetRepository;
import com.backend.tecsys.bdgd.repository.BdgdImportRepository;
import com.backend.tecsys.bdgd.service.BdgdAssetService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class BdgdAssetServiceTest {

    private final BdgdAssetRepository repository = mock(BdgdAssetRepository.class);
    private final BdgdImportRepository importRepository = mock(BdgdImportRepository.class);
    private final BdgdAssetService service = new BdgdAssetService(repository, importRepository, new ObjectMapper());

    @Test
    void shouldReturnConvexHullGeometryForImport() {
        UUID importId = UUID.randomUUID();
        BdgdImportRecord record = new BdgdImportRecord(importId, "ENEL_SP", "SUDESTE",
                LocalDate.now(), "arquivo.gdb", "key", BdgdImportStatus.CONCLUIDO, null, Instant.now());

        when(importRepository.find(importId)).thenReturn(record);
        when(repository.findConvexHullByDistribuidora("ENEL_SP", "SUDESTE")).thenReturn(Map.of(
                "asset_count", 5,
                "hull_geojson", "{\"type\":\"Polygon\",\"coordinates\":[[[0,0],[1,0],[1,1],[0,0]]]}"));

        BdgdBoundsResponse response = service.findBoundsByImportId(importId);

        assertEquals(importId, response.importId());
        assertEquals(5, response.assetCount());
        assertNotNull(response.geometry());
    }

    @Test
    void shouldReturnNullGeometryWhenNotEnoughAssets() {
        UUID importId = UUID.randomUUID();
        BdgdImportRecord record = new BdgdImportRecord(importId, "ENEL_SP", "SUDESTE",
                LocalDate.now(), "arquivo.gdb", "key", BdgdImportStatus.CONCLUIDO, null, Instant.now());

        Map<String, Object> result = new java.util.HashMap<>();
        result.put("asset_count", 0);
        result.put("hull_geojson", null);

        when(importRepository.find(importId)).thenReturn(record);
        when(repository.findConvexHullByDistribuidora("ENEL_SP", "SUDESTE")).thenReturn(result);

        BdgdBoundsResponse response = service.findBoundsByImportId(importId);

        assertEquals(0, response.assetCount());
        assertNull(response.geometry());
    }
}
