package com.backend.tecsys.services;

import com.backend.tecsys.config.BdgdIngestionProperties;
import com.backend.tecsys.exception.InvalidBdgdUploadException;
import com.backend.tecsys.models.BdgdImportRecord;
import com.backend.tecsys.models.BdgdImportResponse;
import com.backend.tecsys.models.BdgdImportStatus;
import com.backend.tecsys.repository.BdgdImportRepository;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Service
public class BdgdIngestionService {
    private final BdgdUploadValidator validator;
    private final BdgdS3StorageService storage;
    private final BdgdImportRepository repository;
    private final BdgdEtlDispatcher dispatcher;
    private final BdgdIngestionProperties properties;

    public BdgdIngestionService(BdgdIngestionProperties properties, BdgdS3StorageService storage,
                                BdgdImportRepository repository, BdgdEtlDispatcher dispatcher) {
        this.properties = properties;
        this.validator = new BdgdUploadValidator(properties.getMaxUploadBytes());
        this.storage = storage;
        this.repository = repository;
        this.dispatcher = dispatcher;
    }

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
}