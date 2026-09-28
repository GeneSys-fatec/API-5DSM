package com.backend.tecsys.bdgd.model;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record BdgdBaseSummaryResponse(
        UUID id,
        String distribuidora,
        String regiao,
        LocalDate dataReferencia,
        String fileName,
        String status,
        int ativosMapeados,
        String projecao,
        Instant createdAt,
        String errorMessage) {
}
