package com.backend.tecsys.scenario.service;

import com.backend.tecsys.bdgd.service.BdgdAssetService;
import com.backend.tecsys.scenario.dto.AssetDto;
import com.backend.tecsys.scenario.dto.SearchAreaRequest;
import com.backend.tecsys.scenario.dto.SearchAreaResponse;
import com.backend.tecsys.scenario.exception.PointOutOfBoundsException;
import com.backend.tecsys.scenario.model.Asset;
import com.backend.tecsys.scenario.model.PolygonPoint;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class SearchAreaService {

    private final com.backend.tecsys.scenario.repository.IAssetRepository assetRepository;
    private final BdgdAssetService bdgdAssetService;

    @Value("${search.area.radius.min:100.0}")
    private Double minRadius;

    @Value("${search.area.radius.max:8000.0}")
    private Double maxRadius;

    public SearchAreaService(
            com.backend.tecsys.scenario.repository.IAssetRepository assetRepository,
            BdgdAssetService bdgdAssetService) {
        this.assetRepository = assetRepository;
        this.bdgdAssetService = bdgdAssetService;
    }

    public SearchAreaResponse processSearchArea(SearchAreaRequest request) {
        if (request.hasPolygon()) {
            return processPolygonSearchArea(request);
        }
        return processRadiusSearchArea(request);
    }

    private SearchAreaResponse processRadiusSearchArea(SearchAreaRequest request) {
        if (request.getRadius() == null || request.getRadius() < minRadius || request.getRadius() > maxRadius) {
            throw new IllegalArgumentException("O raio informado (" + request.getRadius() +
                    "m) deve estar entre " + minRadius + "m e " + maxRadius + "m.");
        }

        BdgdAssetService.BoundaryCheck boundaryCheck = bdgdAssetService.checkPointWithinImportBounds(
                request.getImportId(), request.getLongitude(), request.getLatitude());

        if (boundaryCheck.hasBoundary() && !boundaryCheck.isPointInside()) {
            throw new PointOutOfBoundsException(
                    "O ponto central informado esta fora da area de cobertura da BDGD selecionada.");
        }

        List<AssetDto> candidates = new java.util.ArrayList<>();
        try {
            List<Asset> dbAssets = assetRepository.findWithinRadius(
                    request.getImportId(), request.getLatitude(), request.getLongitude(), request.getRadius());
            if (dbAssets != null && !dbAssets.isEmpty()) {
                candidates = dbAssets.stream().map(this::mapToDto).collect(Collectors.toList());
            }
        } catch (Exception ignored) {
        }

        return buildResponse(candidates, boundaryCheck);
    }

    private SearchAreaResponse processPolygonSearchArea(SearchAreaRequest request) {
        List<PolygonPoint> polygonPoints = request.getPolygonPoints();
        if (polygonPoints.size() < 3) {
            throw new IllegalArgumentException(
                    "O polígono manual deve ter no mínimo 3 pontos para formar uma área válida.");
        }

        BdgdAssetService.BoundaryCheck boundaryCheck = null;
        for (PolygonPoint point : polygonPoints) {
            BdgdAssetService.BoundaryCheck pointCheck = bdgdAssetService.checkPointWithinImportBounds(
                    request.getImportId(), point.longitude(), point.latitude());
            if (pointCheck.hasBoundary() && !pointCheck.isPointInside()) {
                throw new PointOutOfBoundsException(
                        "Um ou mais pontos do polígono estão fora da area de cobertura da BDGD selecionada.");
            }
            boundaryCheck = pointCheck;
        }

        List<AssetDto> candidates = new java.util.ArrayList<>();
        try {
            List<Asset> dbAssets = assetRepository.findWithinPolygon(request.getImportId(), polygonPoints);
            if (dbAssets != null && !dbAssets.isEmpty()) {
                candidates = dbAssets.stream().map(this::mapToDto).collect(Collectors.toList());
            }
        } catch (Exception ignored) {
        }

        return buildResponse(candidates, boundaryCheck);
    }

    private SearchAreaResponse buildResponse(List<AssetDto> candidates, BdgdAssetService.BoundaryCheck boundaryCheck) {
        String validationStatus = "OK";
        String message;

        if (candidates.isEmpty()) {
            message = "Nenhum ativo encontrado para a área informada.";
        } else {
            message = "Área delimitada com sucesso (" + candidates.size() + " ativos encontrados na base BDGD).";
        }

        return SearchAreaResponse.builder()
                .candidates(candidates)
                .validationStatus(validationStatus)
                .message(message)
                .boundaryGeometry(boundaryCheck != null ? boundaryCheck.geometry() : null)
                .build();
    }

    private AssetDto mapToDto(Asset asset) {
        return AssetDto.builder()
                .id(asset.getAssetKey())
                .type(asset.getAssetType())
                .latitude(asset.getCoordinate().latitude())
                .longitude(asset.getCoordinate().longitude())
                .build();
    }
}
