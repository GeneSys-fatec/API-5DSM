package com.backend.tecsys.scenario.service;

import com.backend.tecsys.bdgd.service.BdgdAssetService;
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

    public SearchAreaService(IAssetRepository assetRepository, BdgdAssetService bdgdAssetService) {
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

                Set<String> selectedFilter = null;
                if (request.getSelectedAssetTypes() != null && !request.getSelectedAssetTypes().isEmpty()) {
                    selectedFilter = request.getSelectedAssetTypes().stream()
                            .map(this::canonicalCategory)
                            .collect(Collectors.toSet());
                }

                final Set<String> finalFilter = selectedFilter;
                candidates = dbAssets.stream()
                        .filter(asset -> {
                            if (finalFilter == null) return true;
                            String cat = canonicalCategory(asset.getAssetType());
                            return finalFilter.contains(cat);
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

    private String canonicalCategory(String type) {
        if (type == null || type.isBlank()) {
            return "OUTROS";
        }
        String s = type.trim().toUpperCase();
        if (s.equals("PONNOT") || s.equals("POSTE") || s.equals("POST")) return "POSTE";
        if (s.equals("UNTRMT") || s.equals("TRAFO") || s.equals("TRANSFORMADOR")) return "TRAFO";
        if (s.equals("UNREMT") || s.equals("RELIGADOR") || s.equals("RECLOSER")) return "RELIGADOR";
        if (s.equals("SUB") || s.equals("SUBESTACAO") || s.equals("SUBSTATION")) return "SUB";
        if (s.equals("UCBT")) return "UCBT";
        if (s.equals("UCMT")) return "UCMT";
        if (s.equals("SSDMT")) return "SSDMT";
        if (s.equals("SSDBT")) return "SSDBT";
        if (s.equals("SSDAT")) return "SSDAT";
        if (s.equals("UNCRAT")) return "UNCRAT";
        return s;
    }

    private AssetDto mapToDto(Asset asset) {
        return AssetDto.builder()
                .id(asset.getAssetKey())
                .type(canonicalCategory(asset.getAssetType()))
                .latitude(asset.getCoordinate().latitude())
                .longitude(asset.getCoordinate().longitude())
                .build();
    }
}
