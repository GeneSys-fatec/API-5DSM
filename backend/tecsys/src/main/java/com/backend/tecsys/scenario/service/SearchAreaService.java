package com.backend.tecsys.scenario.service;

import com.backend.tecsys.bdgd.service.BdgdAssetService;
import com.backend.tecsys.scenario.catalog.BdgdAssetCatalog;
import com.backend.tecsys.scenario.dto.AssetDto;
import com.backend.tecsys.scenario.dto.SearchAreaRequest;
import com.backend.tecsys.scenario.dto.SearchAreaResponse;
import com.backend.tecsys.scenario.exception.PointOutOfBoundsException;
import com.backend.tecsys.scenario.model.Asset;
import com.backend.tecsys.scenario.repository.IAssetRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class SearchAreaService {

    @Value("${search.area.radius.min:100.0}")
    private double minRadius;

    @Value("${search.area.radius.max:8000.0}")
    private double maxRadius;

    private final IAssetRepository assetRepository;
    private final BdgdAssetService bdgdAssetService;
    private final BdgdAssetCatalog assetCatalog;

    public SearchAreaService(
            IAssetRepository assetRepository,
            BdgdAssetService bdgdAssetService,
            BdgdAssetCatalog assetCatalog) {
        this.assetRepository = assetRepository;
        this.bdgdAssetService = bdgdAssetService;
        this.assetCatalog = assetCatalog;
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

        List<AssetDto> candidates = new ArrayList<>();
        Map<String, Integer> countsByType = new LinkedHashMap<>();
        List<String> availableTypes = new ArrayList<>();

        try {
            List<Asset> dbAssets = assetRepository.findWithinRadius(
                    request.getImportId(), request.getLatitude(), request.getLongitude(), request.getRadius());
            if (dbAssets != null && !dbAssets.isEmpty()) {
                for (Asset asset : dbAssets) {
                    String type = asset.getAssetType() != null ? asset.getAssetType().trim().toUpperCase() : "OUTROS";
                    countsByType.merge(type, 1, Integer::sum);
                }
                availableTypes.addAll(countsByType.keySet());

                Set<String> expandedFilter = null;
                if (request.getSelectedAssetTypes() != null && !request.getSelectedAssetTypes().isEmpty()) {
                    expandedFilter = assetCatalog.expandFilter(request.getSelectedAssetTypes());
                }

                final Set<String> finalFilter = expandedFilter;
                candidates = dbAssets.stream()
                        .filter(asset -> {
                            if (finalFilter == null) return true;
                            String rawType = asset.getAssetType() != null ? asset.getAssetType().trim().toUpperCase() : "OUTROS";
                            return finalFilter.contains(rawType) || finalFilter.contains(assetCatalog.canonicalCode(rawType));
                        })
                        .map(this::mapToDto)
                        .collect(Collectors.toList());
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
                .countsByType(countsByType)
                .availableTypes(availableTypes)
                .build();
    }

    private AssetDto mapToDto(Asset asset) {
        return AssetDto.builder()
                .id(asset.getAssetKey())
                .type(assetCatalog.canonicalCode(asset.getAssetType()))
                .latitude(asset.getCoordinate().latitude())
                .longitude(asset.getCoordinate().longitude())
                .build();
    }
}
