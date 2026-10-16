package com.backend.tecsys.bdgd.repository;

import com.backend.tecsys.bdgd.exception.BdgdImportNotFoundException;
import com.backend.tecsys.bdgd.model.BdgdImportRecord;
import com.backend.tecsys.bdgd.model.BdgdImportStatus;
import lombok.RequiredArgsConstructor;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
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

    public int updateGroup(UUID id, String regiao, String distribuidora) {
        return jdbc.update("UPDATE bdgd_imports SET regiao = ?, distribuidora = ? WHERE id = ?",
                regiao, distribuidora, id.toString());
    }

    public BdgdImportRecord find(UUID id) {
        return jdbc.query(
                "SELECT id, distribuidora, regiao, data_referencia, file_name, storage_key, status, error_message, created_at FROM bdgd_imports WHERE id = ?",
                this::mapRow, id.toString())
                .stream().findFirst().orElseThrow(BdgdImportNotFoundException::new);
    }

    public List<BdgdImportRecord> findAll() {
        return jdbc.query(
                "SELECT id, distribuidora, regiao, data_referencia, file_name, storage_key, status, error_message, created_at FROM bdgd_imports ORDER BY created_at DESC",
                this::mapRow);
    }

    public List<BdgdImportRecord> findByFilters(String regiao, String distribuidora) {
        StringBuilder sql = new StringBuilder(
                "SELECT id, distribuidora, regiao, data_referencia, file_name, storage_key, status, error_message, created_at FROM bdgd_imports");
        List<Object> params = new ArrayList<>();
        List<String> conditions = new ArrayList<>();
        if (hasText(regiao)) {
            conditions.add("regiao = ?");
            params.add(regiao.trim());
        }
        if (hasText(distribuidora)) {
            conditions.add("distribuidora = ?");
            params.add(distribuidora.trim());
        }
        if (!conditions.isEmpty()) {
            sql.append(" WHERE ").append(String.join(" AND ", conditions));
        }
        sql.append(" ORDER BY created_at DESC");
        return jdbc.query(sql.toString(), this::mapRow, params.toArray());
    }

    public List<String> findRegions() {
        return jdbc.queryForList(
                "SELECT DISTINCT regiao FROM bdgd_imports WHERE regiao IS NOT NULL AND TRIM(regiao) <> '' ORDER BY regiao",
                String.class);
    }

    public List<String> findDistributors() {
        return jdbc.queryForList(
                "SELECT DISTINCT distribuidora FROM bdgd_imports WHERE distribuidora IS NOT NULL AND TRIM(distribuidora) <> '' ORDER BY distribuidora",
                String.class);
    }

    public List<String> findDistributorsByRegion(String regiao) {
        return jdbc.queryForList(
                "SELECT DISTINCT distribuidora FROM bdgd_imports WHERE regiao = ? AND distribuidora IS NOT NULL AND TRIM(distribuidora) <> '' ORDER BY distribuidora",
                String.class, regiao.trim());
    }

    private BdgdImportRecord mapRow(ResultSet rs, int rowNum) throws SQLException {
        return new BdgdImportRecord(UUID.fromString(rs.getString("id")), rs.getString("distribuidora"),
                rs.getString("regiao"), rs.getObject("data_referencia", LocalDate.class), rs.getString("file_name"),
                rs.getString("storage_key"), BdgdImportStatus.valueOf(rs.getString("status")), rs.getString("error_message"),
                rs.getTimestamp("created_at").toInstant());
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
