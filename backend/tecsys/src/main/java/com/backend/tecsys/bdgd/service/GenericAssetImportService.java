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
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

@Slf4j
@Service
@RequiredArgsConstructor
public class GenericAssetImportService {

    private static final int BATCH_SIZE = 500;

    private final CsvAssetParser csvAssetParser;
    private final ExcelAssetParser excelAssetParser;
    private final JsonAssetParser jsonAssetParser;
    private final BdgdImportRepository importRepository;
    private final BdgdInMemoryCache inMemoryCache;
    private final JdbcTemplate jdbcTemplate;
    private final BdgdS3StorageService storage;
    private final PlatformTransactionManager transactionManager;

    public boolean isSupportedTabularFormat(String filename) {
        if (filename == null) {
            return false;
        }
        String lower = filename.toLowerCase(Locale.ROOT);
        return lower.endsWith(".csv") || lower.endsWith(".xls") || lower.endsWith(".xlsx") || lower.endsWith(".json");
    }

    @Async
    public void importTabularAssetsAsync(UUID importId, String storageKey, String filename, String distribuidora, String regiao) {
        try (InputStream is = storage.openStream(storageKey)) {
            importTabularStream(is, filename, importId, distribuidora, regiao);
        } catch (InvalidBdgdUploadException e) {
            log.warn("Falha de validação na importação tabular {}: {}", importId, e.getMessage());
            importRepository.updateStatus(importId, BdgdImportStatus.FALHOU, e.getMessage());
        } catch (Exception e) {
            log.error("Erro inesperado na importação tabular {}: {}", importId, e.getMessage(), e);
            importRepository.updateStatus(importId, BdgdImportStatus.FALHOU, "Falha na importação: " + e.getMessage());
        }
    }

    public int importTabularAssets(MultipartFile file, UUID importId, String distribuidora, String regiao) {
        String filename = file.getOriginalFilename() == null ? "" : file.getOriginalFilename().toLowerCase(Locale.ROOT);
        try (InputStream is = file.getInputStream()) {
            return importTabularStream(is, filename, importId, distribuidora, regiao);
        } catch (InvalidBdgdUploadException e) {
            importRepository.updateStatus(importId, BdgdImportStatus.FALHOU, e.getMessage());
            throw e;
        } catch (Exception e) {
            String msg = "Falha ao ler arquivo: " + e.getMessage();
            importRepository.updateStatus(importId, BdgdImportStatus.FALHOU, msg);
            throw new InvalidBdgdUploadException(msg);
        }
    }

    public int importTabularStream(InputStream inputStream, String filename, UUID importId, String distribuidora, String regiao) {
        ensureAtivoTable();

        String lower = filename == null ? "" : filename.toLowerCase(Locale.ROOT);
        TransactionTemplate txTemplate = new TransactionTemplate(transactionManager);

        AtomicInteger totalImported = new AtomicInteger(0);

        try {
            txTemplate.executeWithoutResult(status -> {
                List<AssetFileRecord> batch = new ArrayList<>(BATCH_SIZE);

                java.util.function.Consumer<AssetFileRecord> consumer = record -> {
                    batch.add(record);
                    if (batch.size() >= BATCH_SIZE) {
                        persistBatch(batch);
                        populateInMemoryCache(batch);
                        totalImported.addAndGet(batch.size());
                        batch.clear();
                    }
                };

                if (lower.endsWith(".csv")) {
                    csvAssetParser.parseAndProcess(inputStream, distribuidora, regiao, consumer);
                } else if (lower.endsWith(".xls") || lower.endsWith(".xlsx")) {
                    excelAssetParser.parseAndProcess(inputStream, distribuidora, regiao, consumer);
                } else if (lower.endsWith(".json")) {
                    jsonAssetParser.parseAndProcess(inputStream, distribuidora, regiao, consumer);
                } else {
                    throw new InvalidBdgdUploadException("Formato de arquivo não suportado para importação tabular: " + filename);
                }

                if (!batch.isEmpty()) {
                    persistBatch(batch);
                    populateInMemoryCache(batch);
                    totalImported.addAndGet(batch.size());
                    batch.clear();
                }
            });

            importRepository.updateStatus(importId, BdgdImportStatus.CONCLUIDO, null);
            log.info("Importação {} concluída com {} ativos importados com sucesso.", importId, totalImported.get());
            return totalImported.get();
        } catch (InvalidBdgdUploadException e) {
            log.error("Erro de validação ao persistir importação {}: {}", importId, e.getMessage());
            importRepository.updateStatus(importId, BdgdImportStatus.FALHOU, e.getMessage());
            throw e;
        } catch (Exception e) {
            log.error("Erro na persistência ao importar {}: {}", importId, e.getMessage(), e);
            String errorMsg = "Erro na persistência: " + (e.getCause() != null ? e.getCause().getMessage() : e.getMessage());
            importRepository.updateStatus(importId, BdgdImportStatus.FALHOU, errorMsg);
            throw new InvalidBdgdUploadException(errorMsg);
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
                        distribuidora VARCHAR(100) NOT NULL,
                        distribuidora_id BIGINT,
                        regiao VARCHAR(100),
                        geom GEOMETRY(Point, 4326)
                    )
                    """);
            jdbcTemplate.execute("CREATE UNIQUE INDEX IF NOT EXISTS uq_bdgd_ativo_dist_key ON bdgd.ativo (distribuidora, ativo_key)");
            jdbcTemplate.execute("CREATE INDEX IF NOT EXISTS idx_bdgd_ativo_geom ON bdgd.ativo USING GIST (geom)");
        } catch (Exception e) {
            log.warn("Não foi possível garantir tabela bdgd.ativo ou índices (PostGIS pode não estar disponível): {}", e.getMessage());
        }
    }

    private void persistBatch(List<AssetFileRecord> records) {
        String upsertSql = """
                INSERT INTO bdgd.ativo (ativo_key, tipo_ativo, distribuidora, regiao, geom)
                VALUES (?, ?, ?, ?, ST_SetSRID(ST_MakePoint(?, ?), 4326))
                ON CONFLICT (distribuidora, ativo_key) DO UPDATE
                SET tipo_ativo = EXCLUDED.tipo_ativo,
                    regiao = EXCLUDED.regiao,
                    geom = EXCLUDED.geom
                """;

        jdbcTemplate.batchUpdate(upsertSql, records, records.size(), (ps, r) -> {
            ps.setString(1, r.assetKey());
            ps.setString(2, r.assetType());
            ps.setString(3, r.distribuidora());
            ps.setString(4, r.regiao());
            ps.setDouble(5, r.longitude());
            ps.setDouble(6, r.latitude());
        });
    }

    private void populateInMemoryCache(List<AssetFileRecord> records) {
        for (AssetFileRecord r : records) {
            Asset asset = Asset.builder()
                    .assetKey(r.assetKey())
                    .assetType(r.assetType())
                    .coordinate(new RfCoordinate(r.latitude(), r.longitude()))
                    .build();
            inMemoryCache.addAsset(r.distribuidora(), asset);
        }
    }
}
