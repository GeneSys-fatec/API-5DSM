package com.backend.tecsys.models;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record N8nWebhookPayload(
        @JsonProperty("import_id") UUID importId,
        @JsonProperty("distribuidora") String distribuidora,
        @JsonProperty("regiao") String regiao,
        @JsonProperty("data") LocalDate data,
        @JsonProperty("file_name") String fileName,
        @JsonProperty("gdb_path") String gdbPath,
        @JsonProperty("storage_key") String storageKey,
        @JsonProperty("created_at") Instant createdAt) {
}
