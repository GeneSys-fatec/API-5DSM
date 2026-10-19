package com.backend.tecsys.scenario.service;

import com.backend.tecsys.bdgd.service.BdgdAssetService;
import com.backend.tecsys.scenario.dto.AssetDto;
import com.backend.tecsys.scenario.dto.SearchAreaRequest;
import com.backend.tecsys.scenario.dto.SearchAreaResponse;
import com.backend.tecsys.scenario.exception.PointOutOfBoundsException;
import com.backend.tecsys.scenario.model.Asset;
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
        if (request.getRadius() < minRadius || request.getRadius() > maxRadius) {
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

        String validationStatus = "OK";
        String message;

        if (candidates.isEmpty()) {
            message = "Nenhum ativo encontrado para as coordenadas e raio informados.";
        } else {
            message = "Área delimitada com sucesso (" + candidates.size() + " ativos encontrados na base BDGD).";
        }

        return SearchAreaResponse.builder()
                .candidates(candidates)
                .validationStatus(validationStatus)
                .message(message)
                .boundaryGeometry(boundaryCheck.geometry())
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
