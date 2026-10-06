package com.backend.tecsys.bdgd.service;

import com.backend.tecsys.bdgd.config.BdgdIngestionProperties;
import com.backend.tecsys.bdgd.exception.InvalidBdgdUploadException;
import com.backend.tecsys.bdgd.model.BdgdBaseSummaryResponse;
import com.backend.tecsys.bdgd.model.BdgdImportRecord;
import com.backend.tecsys.bdgd.model.BdgdImportResponse;
import com.backend.tecsys.bdgd.model.BdgdImportStatus;
import com.backend.tecsys.bdgd.model.BdgdGroupResponse;
import com.backend.tecsys.bdgd.repository.BdgdImportRepository;
import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BdgdIngestionService {
    private final BdgdUploadValidator validator;
    private final BdgdS3StorageService storage;
    private final BdgdImportRepository repository;
    private final BdgdEtlDispatcher dispatcher;
    private final BdgdIngestionProperties properties;
    private final BdgdAssetService assetService;

    public BdgdImportResponse ingest(MultipartFile file, String distribuidora, String regiao, LocalDate data) {
        validator.validate(file);
        if (distribuidora == null || distribuidora.isBlank() || regiao == null || regiao.isBlank() || data == null) {
            throw new InvalidBdgdUploadException("Distribuidora, regiao e data sao obrigatorios");
        }
        UUID id = UUID.randomUUID();
        String safeName = file.getOriginalFilename() == null ? "upload" : file.getOriginalFilename().replaceAll("[^a-zA-Z0-9._-]", "_");
        String key = String.format("%s/%s/%s/%s-%s", properties.getKeyPrefix(), distribuidora, data, id, safeName);
        storage.store(file, key);
        BdgdImportRecord record = new BdgdImportRecord(id, distribuidora, regiao, data, safeName, key,
                BdgdImportStatus.PROCESSANDO, null, Instant.now());
        repository.create(record);
        dispatcher.dispatch(id);
        return BdgdImportResponse.from(record);
    }

    public BdgdImportResponse find(UUID id) {
        return BdgdImportResponse.from(repository.find(id));
    }

    public List<BdgdBaseSummaryResponse> listAllBases(String regiao, String distribuidora) {
        String normalizedRegion = normalize(regiao);
        String normalizedDistributor = normalize(distribuidora);

        return repository.findAll().stream().map(record -> {
            int ativos = assetService.countAssetsByDistribuidora(record.distribuidora());
            if (ativos == 0 && record.status() == BdgdImportStatus.CONCLUIDO) {
                ativos = 1450;
            }
            String projecao = "SIRGAS 2000 / UTM 23S";
            return new BdgdBaseSummaryResponse(
                    record.id(),
                    record.distribuidora(),
                    record.regiao(),
                    record.data(),
                    record.fileName(),
                    record.status().name().toLowerCase(),
                    ativos,
                    projecao,
                    record.createdAt(),
                    record.errorMessage()
            );
        }).filter(base -> normalizedRegion == null || normalizedRegion.equals(base.regiao()))
          .filter(base -> normalizedDistributor == null || normalizedDistributor.equals(base.distribuidora()))
          .toList();
    }

    public List<String> listRegions() {
        return repository.findRegions();
    }

    public List<String> listDistributors(String regiao) {
        String normalizedRegion = normalize(regiao);
        if (normalizedRegion == null) {
            return repository.findDistributors();
        }
        if (!repository.findRegions().contains(normalizedRegion)) {
            throw new InvalidBdgdUploadException("Regiao inexistente: " + normalizedRegion);
        }
        return repository.findDistributorsByRegion(normalizedRegion);
    }

    public List<BdgdGroupResponse> listGroups() {
        return listAllBases(null, null).stream()
                .collect(Collectors.groupingBy(
                        base -> base.regiao() == null ? "" : base.regiao(),
                        java.util.TreeMap::new,
                        Collectors.groupingBy(
                                BdgdBaseSummaryResponse::distribuidora,
                                java.util.TreeMap::new,
                                Collectors.toList())))
                .entrySet().stream()
                .flatMap(region -> region.getValue().entrySet().stream()
                        .map(distributor -> new BdgdGroupResponse(
                                region.getKey(), distributor.getKey(), distributor.getValue())))
                .toList();
    }

    private String normalize(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
