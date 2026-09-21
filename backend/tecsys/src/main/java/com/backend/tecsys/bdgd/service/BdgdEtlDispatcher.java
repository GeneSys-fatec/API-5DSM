package com.backend.tecsys.bdgd.service;

import com.backend.tecsys.bdgd.model.BdgdImportRecord;
import com.backend.tecsys.bdgd.model.BdgdImportStatus;
import com.backend.tecsys.bdgd.model.N8nWebhookPayload;
import com.backend.tecsys.bdgd.repository.BdgdImportRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.nio.file.Path;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class BdgdEtlDispatcher {
    private final BdgdImportRepository repository;
    private final BdgdS3StorageService storage;
    private final N8nWebhookService n8nWebhookService;

    @Async
    public void dispatch(UUID importId) {
        try {
            BdgdImportRecord record = repository.find(importId);
            Path gdbPath = storage.resolveGdbPath(record.storageKey(), record.fileName());

            N8nWebhookPayload payload = new N8nWebhookPayload(
                    record.id(),
                    record.distribuidora(),
                    record.regiao(),
                    record.data(),
                    record.fileName(),
                    gdbPath.toString(),
                    record.storageKey(),
                    record.createdAt()
            );

            log.info("Despachando importacao {} para N8N com gdbPath={}", importId, gdbPath);
            n8nWebhookService.triggerProcessing(payload);
        } catch (Exception exception) {
            log.error("Falha ao despachar webhook N8N para importacao {}: {}", importId, exception.getMessage(), exception);
            repository.updateStatus(importId, BdgdImportStatus.FALHOU, exception.getMessage());
        }
    }
}
