package com.backend.tecsys.bdgd.service;

import com.backend.tecsys.bdgd.exception.InvalidBdgdUploadException;
import com.backend.tecsys.bdgd.model.AssetFileRecord;
import com.backend.tecsys.bdgd.model.BdgdImportStatus;
import com.backend.tecsys.bdgd.parser.CsvAssetParser;
import com.backend.tecsys.bdgd.parser.ExcelAssetParser;
import com.backend.tecsys.bdgd.parser.JsonAssetParser;
import com.backend.tecsys.bdgd.repository.BdgdAssetRepository;
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

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

@Slf4j
@Service
@RequiredArgsConstructor
public class GenericAssetImportService {

    private static final int BATCH_SIZE = 500;

    private static final Map<String, String> LAYER_TABLE_MAP = Map.ofEntries(
            Map.entry("POSTE", "poste"),
            Map.entry("POST", "poste"),
            Map.entry("TRAFO", "poste"),
            Map.entry("TRANSFORMADOR", "poste"),
            Map.entry("RELIGADOR", "poste"),
            Map.entry("CHAVE", "poste"),
            Map.entry("SUB", "sub"),
            Map.entry("SUBESTACAO", "sub"),
            Map.entry("SUBESTAÇÃO", "sub"),
            Map.entry("SE", "sub"),
            Map.entry("UCBT", "ucbt"),
            Map.entry("UC_BT", "ucbt"),
            Map.entry("UCMT", "ucmt"),
            Map.entry("UC_MT", "ucmt"),
            Map.entry("SSDBT", "ssdbt"),
            Map.entry("SSD_BT", "ssdbt"),
            Map.entry("SSDMT", "ssdmt"),
            Map.entry("SSD_MT", "ssdmt"),
            Map.entry("SSDAT", "ssdat"),
            Map.entry("SSD_AT", "ssdat")
    );

    private final CsvAssetParser csvAssetParser;
    private final ExcelAssetParser excelAssetParser;
    private final JsonAssetParser jsonAssetParser;
    private final BdgdImportRepository importRepository;
    private final BdgdInMemoryCache inMemoryCache;
    private final JdbcTemplate jdbcTemplate;
    private final BdgdS3StorageService storage;
    private final PlatformTransactionManager transactionManager;
    private final BdgdAssetRepository bdgdAssetRepository;

    public boolean isSupportedTabularFormat(String filename) {
        if (filename == null) {
            return false;
        }
        String lower = filename.toLowerCase(Locale.ROOT);
        return lower.endsWith(".csv") || lower.endsWith(".xls") || lower.endsWith(".xlsx") || lower.endsWith(".json");
    }

    public boolean isZipContainingTabular(InputStream inputStream) {
        try (ZipInputStream zis = new ZipInputStream(inputStream)) {
            ZipEntry entry;
            boolean hasGdb = false;
            boolean hasTabular = false;
            while ((entry = zis.getNextEntry()) != null) {
                if (BdgdUploadValidator.isGdbEntry(entry.getName())) {
                    hasGdb = true;
                }
                if (BdgdUploadValidator.isTabularEntry(entry.getName())) {
                    hasTabular = true;
                }
                zis.closeEntry();
            }
            return hasTabular && !hasGdb;
        } catch (Exception e) {
            log.warn("Erro ao inspecionar arquivo ZIP para ativos tabulares: {}", e.getMessage());
            return false;
        }
    }

    public static String resolveTableName(String assetType) {
        if (assetType == null) {
            return "poste";
        }
        String norm = assetType.trim().toUpperCase(Locale.ROOT).replace("-", "_").replace(" ", "_");
        return LAYER_TABLE_MAP.getOrDefault(norm, "poste");
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
        ensureTables();

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

                try {
                    if (lower.endsWith(".zip")) {
                        importTabularZipStream(inputStream, distribuidora, regiao, consumer);
                    } else if (lower.endsWith(".csv")) {
                        csvAssetParser.parseAndProcess(inputStream, distribuidora, regiao, consumer);
                    } else if (lower.endsWith(".xls") || lower.endsWith(".xlsx")) {
                        excelAssetParser.parseAndProcess(inputStream, distribuidora, regiao, consumer);
                    } else if (lower.endsWith(".json")) {
                        jsonAssetParser.parseAndProcess(inputStream, distribuidora, regiao, consumer);
                    } else {
                        throw new InvalidBdgdUploadException("Formato de arquivo não suportado para importação tabular: " + filename);
                    }
                } catch (InvalidBdgdUploadException e) {
                    throw e;
                } catch (Exception e) {
                    throw new InvalidBdgdUploadException("Falha ao processar arquivo tabular: " + e.getMessage());
                }

                if (!batch.isEmpty()) {
                    persistBatch(batch);
                    populateInMemoryCache(batch);
                    totalImported.addAndGet(batch.size());
                    batch.clear();
                }
            });

            bdgdAssetRepository.invalidateCache();
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

    private void importTabularZipStream(
            InputStream inputStream,
            String distribuidora,
            String regiao,
            java.util.function.Consumer<AssetFileRecord> consumer) throws Exception {

        try (ZipInputStream zis = new ZipInputStream(inputStream)) {
            ZipEntry entry;
            boolean processedAny = false;

            while ((entry = zis.getNextEntry()) != null) {
                String entryName = entry.getName();
                if (entry.isDirectory() || !BdgdUploadValidator.isTabularEntry(entryName)) {
                    zis.closeEntry();
                    continue;
                }

                String entryLower = entryName.toLowerCase(Locale.ROOT);
                byte[] entryBytes = zis.readAllBytes();
                if (entryBytes.length == 0) {
                    zis.closeEntry();
                    continue;
                }

                try (ByteArrayInputStream bais = new ByteArrayInputStream(entryBytes)) {
                    if (entryLower.endsWith(".csv")) {
                        csvAssetParser.parseAndProcess(bais, distribuidora, regiao, consumer);
                        processedAny = true;
                    } else if (entryLower.endsWith(".xls") || entryLower.endsWith(".xlsx")) {
                        excelAssetParser.parseAndProcess(bais, distribuidora, regiao, consumer);
                        processedAny = true;
                    } else if (entryLower.endsWith(".json")) {
                        jsonAssetParser.parseAndProcess(bais, distribuidora, regiao, consumer);
                        processedAny = true;
                    }
                }
                zis.closeEntry();
            }

            if (!processedAny) {
                throw new InvalidBdgdUploadException("Nenhum arquivo tabular (.csv, .xls, .xlsx, .json) válido encontrado no ZIP.");
            }
        }
    }

    private void ensureTables() {
        try {
            jdbcTemplate.execute("CREATE SCHEMA IF NOT EXISTS bdgd");
            List<String> tables = List.of("poste", "sub", "ucbt", "ucmt", "ssdbt", "ssdmt", "ssdat");
            for (String table : tables) {
                String geomType = ("sub".equals(table) || table.startsWith("ssd")) ? "Geometry" : "Point";
                jdbcTemplate.execute(String.format("""
                        CREATE TABLE IF NOT EXISTS bdgd.%s (
                            id BIGSERIAL PRIMARY KEY,
                            tipo_ativo TEXT NOT NULL,
                            distribuidora TEXT NOT NULL,
                            regiao TEXT NOT NULL,
                            asset_key TEXT NOT NULL,
                            geometry GEOMETRY(%s, 4326) NOT NULL
                        )
                        """, table, geomType));
                jdbcTemplate.execute(String.format(
                        "CREATE UNIQUE INDEX IF NOT EXISTS uq_%s_asset_key ON bdgd.%s (asset_key)",
                        table, table));
                jdbcTemplate.execute(String.format(
                        "CREATE INDEX IF NOT EXISTS idx_%s_geometry ON bdgd.%s USING GIST (geometry)",
                        table, table));
            }
        } catch (Exception e) {
            log.warn("Não foi possível garantir tabelas da BDGD ou índices (PostGIS pode não estar disponível): {}", e.getMessage());
        }
    }

    private void persistBatch(List<AssetFileRecord> records) {
        Map<String, List<AssetFileRecord>> byTable = records.stream()
                .collect(Collectors.groupingBy(r -> resolveTableName(r.assetType())));

        for (Map.Entry<String, List<AssetFileRecord>> entry : byTable.entrySet()) {
            String table = entry.getKey();
            List<AssetFileRecord> tableRecords = entry.getValue();

            String upsertSql = String.format("""
                    INSERT INTO bdgd.%s (tipo_ativo, distribuidora, regiao, asset_key, geometry)
                    VALUES (?, ?, ?, ?, ST_SetSRID(ST_MakePoint(?, ?), 4326))
                    ON CONFLICT (asset_key) DO UPDATE
                    SET tipo_ativo = EXCLUDED.tipo_ativo,
                        distribuidora = EXCLUDED.distribuidora,
                        regiao = EXCLUDED.regiao,
                        geometry = EXCLUDED.geometry
                    """, table);

            jdbcTemplate.batchUpdate(upsertSql, tableRecords, tableRecords.size(), (ps, r) -> {
                ps.setString(1, r.assetType());
                ps.setString(2, r.distribuidora());
                ps.setString(3, r.regiao());
                ps.setString(4, r.assetKey());
                ps.setDouble(5, r.longitude());
                ps.setDouble(6, r.latitude());
            });
        }
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
