package com.backend.tecsys.bdgd.repository;

import com.backend.tecsys.bdgd.exception.BdgdImportNotFoundException;
import com.backend.tecsys.bdgd.model.BdgdImportRecord;
import com.backend.tecsys.bdgd.model.BdgdImportStatus;
import lombok.RequiredArgsConstructor;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class BdgdImportRepository {
    private final JdbcTemplate jdbc;

    public void create(BdgdImportRecord record) {
        jdbc.update("INSERT INTO bdgd_imports (id, distribuidora, regiao, data_referencia, file_name, storage_key, status, error_message, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                record.id().toString(), record.distribuidora(), record.regiao(), record.data(), record.fileName(),
                record.storageKey(), record.status().name(), record.errorMessage(), Timestamp.from(record.createdAt()));
    }

    public void updateStatus(UUID id, BdgdImportStatus status, String errorMessage) {
        jdbc.update("UPDATE bdgd_imports SET status = ?, error_message = ? WHERE id = ?", status.name(), errorMessage, id.toString());
    }

    public BdgdImportRecord find(UUID id) {
        return jdbc.query("SELECT id, distribuidora, regiao, data_referencia, file_name, storage_key, status, error_message, created_at FROM bdgd_imports WHERE id = ?",
                (rs, row) -> new BdgdImportRecord(UUID.fromString(rs.getString("id")), rs.getString("distribuidora"),
                        rs.getString("regiao"), rs.getObject("data_referencia", LocalDate.class), rs.getString("file_name"),
                        rs.getString("storage_key"), BdgdImportStatus.valueOf(rs.getString("status")), rs.getString("error_message"),
                        rs.getTimestamp("created_at").toInstant()), id.toString()).stream().findFirst().orElseThrow(BdgdImportNotFoundException::new);
    }
}
