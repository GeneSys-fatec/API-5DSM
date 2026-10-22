package com.backend.tecsys;

import com.backend.tecsys.bdgd.service.BdgdAssetService;
import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.scenario.dto.SearchAreaRequest;
import com.backend.tecsys.scenario.dto.SearchAreaResponse;
import com.backend.tecsys.scenario.exception.PointOutOfBoundsException;
import com.backend.tecsys.scenario.model.Asset;
import com.backend.tecsys.scenario.repository.IAssetRepository;
import com.backend.tecsys.scenario.service.SearchAreaService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class SearchAreaServiceTest {

    private final IAssetRepository assetRepository = mock(IAssetRepository.class);
    private final BdgdAssetService bdgdAssetService = mock(BdgdAssetService.class);
    private SearchAreaService service;

    @BeforeEach
    void setUp() {
        service = new SearchAreaService(assetRepository, bdgdAssetService);
        ReflectionTestUtils.setField(service, "minRadius", 100.0);
        ReflectionTestUtils.setField(service, "maxRadius", 8000.0);
    }

    @Test
    void shouldRejectPointOutsideBoundary() {
        UUID importId = UUID.randomUUID();
        when(bdgdAssetService.checkPointWithinImportBounds(any(), anyDouble(), anyDouble()))
                .thenReturn(new BdgdAssetService.BoundaryCheck(samplePolygon(), false));

        SearchAreaRequest request = SearchAreaRequest.builder()
                .importId(importId).latitude(10.0).longitude(10.0).radius(500.0).build();

        assertThrows(PointOutOfBoundsException.class, () -> service.processSearchArea(request));
    }

    @Test
    void shouldAcceptPointInsideBoundary() {
        UUID importId = UUID.randomUUID();
        when(bdgdAssetService.checkPointWithinImportBounds(any(), anyDouble(), anyDouble()))
                .thenReturn(new BdgdAssetService.BoundaryCheck(samplePolygon(), true));
        when(assetRepository.findWithinRadius(any(), anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(List.of());

        SearchAreaRequest request = SearchAreaRequest.builder()
                .importId(importId).latitude(-22.0).longitude(-47.0).radius(500.0).build();

        SearchAreaResponse response = service.processSearchArea(request);

        assertEquals("OK", response.getValidationStatus());
        assertTrue(response.getCandidates().isEmpty());
    }

    @Test
    void shouldAcceptPointWhenNoBoundaryIsAvailable() {
        UUID importId = UUID.randomUUID();
        when(bdgdAssetService.checkPointWithinImportBounds(any(), anyDouble(), anyDouble()))
                .thenReturn(new BdgdAssetService.BoundaryCheck(null, null));
        when(assetRepository.findWithinRadius(any(), anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(List.of());

        SearchAreaRequest request = SearchAreaRequest.builder()
                .importId(importId).latitude(-22.0).longitude(-47.0).radius(500.0).build();

        SearchAreaResponse response = service.processSearchArea(request);

        assertEquals("OK", response.getValidationStatus());
    }

    @Test
    void shouldReturnCountsByTypeAndFilterCandidatesBySelectedTypes() {
        UUID importId = UUID.randomUUID();
        when(bdgdAssetService.checkPointWithinImportBounds(any(), anyDouble(), anyDouble()))
                .thenReturn(new BdgdAssetService.BoundaryCheck(null, null));

        List<Asset> assets = List.of(
                Asset.builder().assetKey("P1").assetType("POSTE").coordinate(new RfCoordinate(-22.0, -47.0)).build(),
                Asset.builder().assetKey("P2").assetType("POSTE").coordinate(new RfCoordinate(-22.01, -47.01)).build(),
                Asset.builder().assetKey("T1").assetType("UNTRMT").coordinate(new RfCoordinate(-22.02, -47.02)).build(),
                Asset.builder().assetKey("S1").assetType("SUB").coordinate(new RfCoordinate(-22.03, -47.03)).build(),
                Asset.builder().assetKey("U1").assetType("UCBT").coordinate(new RfCoordinate(-22.04, -47.04)).build()
        );
        when(assetRepository.findWithinRadius(any(), anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(assets);

        // Request with filter for POSTE and SUB only
        SearchAreaRequest request = SearchAreaRequest.builder()
                .importId(importId)
                .latitude(-22.0)
                .longitude(-47.0)
                .radius(1000.0)
                .selectedAssetTypes(List.of("POSTE", "SUB"))
                .build();

        SearchAreaResponse response = service.processSearchArea(request);

        assertEquals("OK", response.getValidationStatus());
        assertEquals(3, response.getCandidates().size()); // 2 POSTE + 1 SUB
        assertEquals(2, response.getCountsByType().get("POSTE"));
        assertEquals(1, response.getCountsByType().get("UNTRMT"));
        assertEquals(1, response.getCountsByType().get("SUB"));
        assertEquals(1, response.getCountsByType().get("UCBT"));
        assertTrue(response.getAvailableTypes().containsAll(List.of("POSTE", "UNTRMT", "SUB", "UCBT")));
    }

    private Object samplePolygon() {
        return java.util.Map.of("type", "Polygon", "coordinates", List.of());
    }
}
