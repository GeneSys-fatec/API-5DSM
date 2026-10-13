package com.backend.tecsys.bdgd.service;

import com.backend.tecsys.bdgd.exception.InvalidBdgdUploadException;
import com.backend.tecsys.bdgd.model.AssetFileRecord;
import com.backend.tecsys.bdgd.model.BdgdImportStatus;
import com.backend.tecsys.bdgd.parser.CsvAssetParser;
import com.backend.tecsys.bdgd.parser.ExcelAssetParser;
import com.backend.tecsys.bdgd.parser.JsonAssetParser;
import com.backend.tecsys.bdgd.repository.BdgdImportRepository;
import com.backend.tecsys.infrastructure.persistence.BdgdInMemoryCache;
import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.scenario.model.Asset;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class GenericAssetImportService {

    private final CsvAssetParser csvAssetParser;
    private final ExcelAssetParser excelAssetParser;
    private final JsonAssetParser jsonAssetParser;
    private final BdgdImportRepository importRepository;
    private final BdgdInMemoryCache inMemoryCache;
    private final JdbcTemplate jdbcTemplate;

    public boolean isSupportedTabularFormat(String filename) {
        if (filename == null) {
            return false;
        }
        String lower = filename.toLowerCase(Locale.ROOT);
        return lower.endsWith(".csv") || lower.endsWith(".xls") || lower.endsWith(".xlsx") || lower.endsWith(".json");
    }

    public int importTabularAssets(MultipartFile file, UUID importId, String distribuidora, String regiao) {
        String filename = file.getOriginalFilename() == null ? "" : file.getOriginalFilename().toLowerCase(Locale.ROOT);
        List<AssetFileRecord> records;

        try (InputStream is = file.getInputStream()) {
            if (filename.endsWith(".csv")) {
                records = csvAssetParser.parse(is, distribuidora, regiao);
            } else if (filename.endsWith(".xls") || filename.endsWith(".xlsx")) {
                records = excelAssetParser.parse(is, distribuidora, regiao);
            } else if (filename.endsWith(".json")) {
                records = jsonAssetParser.parse(is, distribuidora, regiao);
            } else {
                throw new InvalidBdgdUploadException("Formato de arquivo não suportado para importação tabular: " + filename);
            }
        } catch (InvalidBdgdUploadException e) {
            importRepository.updateStatus(importId, BdgdImportStatus.FALHOU, e.getMessage());
            throw e;
        } catch (Exception e) {
            String msg = "Falha ao ler arquivo: " + e.getMessage();
            importRepository.updateStatus(importId, BdgdImportStatus.FALHOU, msg);
            throw new InvalidBdgdUploadException(msg);
        }

        try {
            ensureAtivoTable();
            persistAssets(records);
            populateInMemoryCache(records);
            importRepository.updateStatus(importId, BdgdImportStatus.CONCLUIDO, null);
            log.info("Importação {} concluída com {} ativos importados com sucesso.", importId, records.size());
            return records.size();
        } catch (Exception e) {
            log.error("Erro ao persistir ativos importados da importação {}: {}", importId, e.getMessage(), e);
            importRepository.updateStatus(importId, BdgdImportStatus.FALHOU, "Erro na persistência: " + e.getMessage());
            throw new InvalidBdgdUploadException("Falha ao salvar ativos importados: " + e.getMessage());
        }
    }

    private void ensureAtivoTable() {
        try {
            jdbcTemplate.execute("CREATE SCHEMA IF NOT EXISTS bdgd");
            jdbcTemplate.execute("""
                    CREATE TABLE IF NOT EXISTS bdgd.ativo (
                        id BIGSERIAL PRIMARY KEY,
                        ativo_key VARCHAR(100) NOT NULL,
                        tipo_ativo VARCHAR(50) NOT NULL,
                        distribuidora VARCHAR(100),
                        distribuidora_id BIGINT,
                        regiao VARCHAR(100),
                        geom GEOMETRY(Point, 4326)
                    )
                    """);
            jdbcTemplate.execute("CREATE UNIQUE INDEX IF NOT EXISTS uq_bdgd_ativo_key ON bdgd.ativo (ativo_key)");
        } catch (Exception e) {
            log.warn("Não foi possível garantir tabela bdgd.ativo (PostGIS pode não estar disponível): {}", e.getMessage());
        }
    }

    private void persistAssets(List<AssetFileRecord> records) {
        String upsertSql = """
                INSERT INTO bdgd.ativo (ativo_key, tipo_ativo, distribuidora, regiao, geom)
                VALUES (?, ?, ?, ?, ST_SetSRID(ST_MakePoint(?, ?), 4326))
                ON CONFLICT (ativo_key) DO UPDATE
                SET tipo_ativo = EXCLUDED.tipo_ativo,
                    distribuidora = EXCLUDED.distribuidora,
                    regiao = EXCLUDED.regiao,
                    geom = EXCLUDED.geom
                """;

        try {
            jdbcTemplate.batchUpdate(upsertSql, records, 100, (ps, r) -> {
                ps.setString(1, r.assetKey());
                ps.setString(2, r.assetType());
                ps.setString(3, r.distribuidora());
                ps.setString(4, r.regiao());
                ps.setDouble(5, r.longitude());
                ps.setDouble(6, r.latitude());
            });
        } catch (Exception e) {
            log.warn("Falha no batchUpdate em bdgd.ativo: {}", e.getMessage());
        }
    }

    private void populateInMemoryCache(List<AssetFileRecord> records) {
        for (AssetFileRecord r : records) {
            Asset asset = Asset.builder()
                    .assetKey(r.assetKey())
                    .assetType(r.assetType())
                    .coordinate(new RfCoordinate(r.latitude(), r.longitude()))
                    .build();
            inMemoryCache.addAsset(asset);
        }
    }
}
