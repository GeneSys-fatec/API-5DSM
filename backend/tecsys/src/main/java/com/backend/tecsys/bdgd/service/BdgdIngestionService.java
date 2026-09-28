package com.backend.tecsys.bdgd.service;

import com.backend.tecsys.bdgd.config.BdgdIngestionProperties;
import com.backend.tecsys.bdgd.exception.InvalidBdgdUploadException;
import com.backend.tecsys.bdgd.model.BdgdBaseSummaryResponse;
import com.backend.tecsys.bdgd.model.BdgdImportRecord;
import com.backend.tecsys.bdgd.model.BdgdImportResponse;
import com.backend.tecsys.bdgd.model.BdgdImportStatus;
import com.backend.tecsys.bdgd.repository.BdgdImportRepository;
import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

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

    public List<BdgdBaseSummaryResponse> listAllBases() {
        return repository.findAll().stream().map(record -> {
            int ativos = assetService.countAssetsByDistribuidora(record.distribuidora());
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
        }).toList();
    }
}
