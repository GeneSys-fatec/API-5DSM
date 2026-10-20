package com.backend.tecsys.bdgd.controller;

import com.backend.tecsys.bdgd.model.BdgdBaseSummaryResponse;
import com.backend.tecsys.bdgd.model.BdgdBoundsResponse;
import com.backend.tecsys.bdgd.model.BdgdGeoJsonResponse;
import com.backend.tecsys.bdgd.model.BdgdGroupUpdateRequest;
import com.backend.tecsys.bdgd.model.BdgdImportOptionsResponse;
import com.backend.tecsys.bdgd.model.BdgdImportResponse;
import com.backend.tecsys.bdgd.service.BdgdAssetService;
import com.backend.tecsys.bdgd.service.BdgdIngestionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.util.List;
import com.backend.tecsys.bdgd.service.BdgdExternalDataService;
import java.util.UUID;

@RestController
@RequestMapping("/api/bdgd")
@RequiredArgsConstructor
public class BdgdIngestionController {

    private final BdgdIngestionService ingestionService;
    private final BdgdAssetService assetService;
    private final BdgdExternalDataService externalDataService;

    @GetMapping({"", "/bases"})
    public List<BdgdBaseSummaryResponse> listBases(
            @RequestParam(required = false) String regiao,
            @RequestParam(required = false) String distribuidora) {
        return ingestionService.listAllBases(regiao, distribuidora);
    }

    @GetMapping({"/options", "/import-options"})
    public BdgdImportOptionsResponse getImportOptions() {
        return externalDataService.getImportOptions();
    }

    @GetMapping("/regions")
    public List<String> listRegions() {
        return ingestionService.listRegions();
    }

    @GetMapping("/distributors")
    public List<String> listDistributors(@RequestParam(required = false) String regiao) {
        return ingestionService.listDistributors(regiao);
    }

    @GetMapping("/map")
    public BdgdGeoJsonResponse map(
            @RequestParam String layer,
            @RequestParam(required = false) String distribuidora,
            @RequestParam(required = false) String regiao,
            @RequestParam(required = false) Integer limit,
            @RequestParam(required = false) Integer offset,
            @RequestParam(required = false) Double minLon,
            @RequestParam(required = false) Double minLat,
            @RequestParam(required = false) Double maxLon,
            @RequestParam(required = false) Double maxLat) {
        return assetService.findFeatures(layer, distribuidora, regiao, limit, offset,
                minLon, minLat, maxLon, maxLat);
    }

    @GetMapping(value = "/map.geojson", produces = "application/geo+json")
    public BdgdGeoJsonResponse mapGeoJson(
            @RequestParam String layer,
            @RequestParam(required = false) String distribuidora,
            @RequestParam(required = false) String regiao,
            @RequestParam(required = false) Integer limit,
            @RequestParam(required = false) Integer offset,
            @RequestParam(required = false) Double minLon,
            @RequestParam(required = false) Double minLat,
            @RequestParam(required = false) Double maxLon,
            @RequestParam(required = false) Double maxLat) {
        return assetService.findFeatures(layer, distribuidora, regiao, limit, offset,
                minLon, minLat, maxLon, maxLat);
    }

    @PostMapping(path = {"", "/upload"}, consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.ACCEPTED)
    public BdgdImportResponse upload(
            @RequestParam("file") MultipartFile file,
            @RequestParam("distribuidora") String distribuidora,
            @RequestParam("regiao") String regiao,
            @RequestParam("data") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate data) {
        return ingestionService.ingest(file, distribuidora, regiao, data);
    }

    @GetMapping("/{id}")
    public BdgdImportResponse findById(@PathVariable UUID id) {
        return ingestionService.find(id);
    }

    @PatchMapping("/{id}")
    public BdgdBaseSummaryResponse updateGroup(@PathVariable UUID id, @Valid @RequestBody BdgdGroupUpdateRequest request) {
        return ingestionService.updateGroup(id, request.regiao(), request.distribuidora());
    }

    @GetMapping("/{id}/bounds")
    public BdgdBoundsResponse bounds(@PathVariable UUID id) {
        return assetService.findBoundsByImportId(id);
    }
}
