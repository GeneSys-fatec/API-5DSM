package com.backend.tecsys.models;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record BdgdImportRecord(
        UUID id,
        String distribuidora,
        String regiao,
        LocalDate data,
        String fileName,
        String storageKey,
        BdgdImportStatus status,
        String errorMessage,
        Instant createdAt) {
}