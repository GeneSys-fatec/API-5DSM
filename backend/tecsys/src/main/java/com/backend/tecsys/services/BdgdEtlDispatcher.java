package com.backend.tecsys.services;

import com.backend.tecsys.models.BdgdImportStatus;
import com.backend.tecsys.repository.BdgdImportRepository;

import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class BdgdEtlDispatcher {
    private final BdgdImportRepository repository;

    public BdgdEtlDispatcher(BdgdImportRepository repository) {
        this.repository = repository;
    }

    @Async
    public void dispatch(UUID importId) {
        try {
            repository.updateStatus(importId, BdgdImportStatus.CONCLUIDO, null);
        } catch (RuntimeException exception) {
            repository.updateStatus(importId, BdgdImportStatus.FALHOU, exception.getMessage());
        }
    }
}