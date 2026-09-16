package com.backend.tecsys.models;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record BdgdImportResponse(
        UUID importId,
        String distribuidora,
        String regiao,
        LocalDate data,
        String status,
        Instant createdAt,
        String errorMessage) {

    static BdgdImportResponse from(BdgdImportRecord record) {
        return new BdgdImportResponse(record.id(), record.distribuidora(), record.regiao(), record.data(),
                record.status().name().toLowerCase(), record.createdAt(), record.errorMessage());
    }
}