package com.backend.tecsys;

import com.backend.tecsys.bdgd.service.BdgdAssetService;
import com.backend.tecsys.scenario.dto.SearchAreaRequest;
import com.backend.tecsys.scenario.dto.SearchAreaResponse;
import com.backend.tecsys.scenario.exception.PointOutOfBoundsException;
import com.backend.tecsys.scenario.repository.IAssetRepository;
import com.backend.tecsys.scenario.service.SearchAreaService;
import com.backend.tecsys.scenario.model.PolygonPoint;
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
    void shouldRejectPolygonSearchWithFewerThanThreePoints() {
        UUID importId = UUID.randomUUID();

        SearchAreaRequest request = SearchAreaRequest.builder()
                .importId(importId)
                .latitude(-22.0).longitude(-47.0)
                .polygonPoints(List.of(
                        new PolygonPoint(-22.0, -47.0),
                        new PolygonPoint(-22.1, -47.1)))
                .build();

        assertThrows(IllegalArgumentException.class, () -> service.processSearchArea(request));
    }

    @Test
    void shouldRejectPolygonSearchWhenAnyVertexIsOutsideBoundary() {
        UUID importId = UUID.randomUUID();
        when(bdgdAssetService.checkPointWithinImportBounds(any(), anyDouble(), anyDouble()))
                .thenReturn(new BdgdAssetService.BoundaryCheck(samplePolygon(), true))
                .thenReturn(new BdgdAssetService.BoundaryCheck(samplePolygon(), false));

        SearchAreaRequest request = SearchAreaRequest.builder()
                .importId(importId)
                .latitude(-22.0).longitude(-47.0)
                .polygonPoints(List.of(
                        new PolygonPoint(-22.0, -47.0),
                        new PolygonPoint(-22.1, -47.1),
                        new PolygonPoint(10.0, 10.0)))
                .build();

        assertThrows(PointOutOfBoundsException.class, () -> service.processSearchArea(request));
    }

    @Test
    void shouldAcceptPolygonSearchWhenAllVerticesAreInsideBoundary() {
        UUID importId = UUID.randomUUID();
        when(bdgdAssetService.checkPointWithinImportBounds(any(), anyDouble(), anyDouble()))
                .thenReturn(new BdgdAssetService.BoundaryCheck(samplePolygon(), true));
        when(assetRepository.findWithinPolygon(any(), any()))
                .thenReturn(List.of());

        SearchAreaRequest request = SearchAreaRequest.builder()
                .importId(importId)
                .latitude(-22.0).longitude(-47.0)
                .polygonPoints(List.of(
                        new PolygonPoint(-22.0, -47.0),
                        new PolygonPoint(-22.1, -47.1),
                        new PolygonPoint(-22.0, -47.2)))
                .build();

        SearchAreaResponse response = service.processSearchArea(request);

        assertEquals("OK", response.getValidationStatus());
        assertTrue(response.getCandidates().isEmpty());
    }

    private Object samplePolygon() {
        return java.util.Map.of("type", "Polygon", "coordinates", List.of());
    }
}
