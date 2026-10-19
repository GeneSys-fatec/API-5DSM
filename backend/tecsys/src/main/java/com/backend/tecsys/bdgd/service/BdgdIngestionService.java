package com.backend.tecsys.bdgd.service;

import com.backend.tecsys.bdgd.config.BdgdIngestionProperties;
import com.backend.tecsys.bdgd.exception.InvalidBdgdUploadException;
import com.backend.tecsys.bdgd.model.BdgdBaseSummaryResponse;
import com.backend.tecsys.bdgd.model.BdgdImportRecord;
import com.backend.tecsys.bdgd.model.BdgdImportResponse;
import com.backend.tecsys.bdgd.model.BdgdImportStatus;
import com.backend.tecsys.bdgd.repository.BdgdImportRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
@RequiredArgsConstructor
public class BdgdIngestionService {
    private static final Duration ATIVOS_CACHE_TTL = Duration.ofMinutes(5);
    private static final Duration ATIVOS_REGISTRO_RETENCAO = Duration.ofHours(24);
    private static final int MAX_ATIVOS_REGISTROS = 512;

    private final BdgdUploadValidator validator;
    private final BdgdGroupValidator groupValidator;
    private final BdgdS3StorageService storage;
    private final BdgdImportRepository repository;
    private final BdgdEtlDispatcher dispatcher;
    private final BdgdIngestionProperties properties;
    private final BdgdAssetService assetService;

    private record AtivosRegistrados(String distribuidoraNaImportacao, int quantidade, Instant calculadoEm) {
        boolean contagemExpirada() {
            return Duration.between(calculadoEm, Instant.now()).compareTo(ATIVOS_CACHE_TTL) >= 0;
        }
    }

    private final Map<UUID, AtivosRegistrados> ativosPorImport = new ConcurrentHashMap<>();

    public BdgdImportResponse ingest(MultipartFile file, String distribuidora, String regiao, LocalDate data) {
        validator.validate(file);
        String normalizedDistributor = groupValidator.normalizeAndValidate(distribuidora, "Distribuidora");
        String normalizedRegion = groupValidator.normalizeAndValidate(regiao, "Regiao");
        if (data == null) {
            throw new InvalidBdgdUploadException("Data e obrigatoria");
        }
        String safeName = file.getOriginalFilename() == null ? "upload" : file.getOriginalFilename().replaceAll("[^a-zA-Z0-9._-]", "_");
        LocalDate referenceDate = BdgdReferenceDateParser.parseOrDefault(safeName, data);
        UUID id = UUID.randomUUID();
        String key = String.format("%s/%s/%s/%s-%s", properties.getKeyPrefix(), normalizedDistributor, referenceDate, id, safeName);
        storage.store(file, key);
        BdgdImportRecord record = new BdgdImportRecord(id, normalizedDistributor, normalizedRegion, referenceDate, safeName, key,
                BdgdImportStatus.PROCESSANDO, null, Instant.now());
        repository.create(record);
        dispatcher.dispatch(id);
        return BdgdImportResponse.from(record);
    }

    public BdgdImportResponse find(UUID id) {
        return BdgdImportResponse.from(repository.find(id));
    }

    public List<BdgdBaseSummaryResponse> listAllBases(String regiao, String distribuidora) {
        return repository.findByFilters(groupValidator.normalize(regiao), groupValidator.normalize(distribuidora)).stream()
                .map(this::toSummary)
                .toList();
    }

    public List<BdgdBaseSummaryResponse> listAllBases() {
        return listAllBases(null, null);
    }

    public BdgdBaseSummaryResponse updateGroup(UUID id, String regiao, String distribuidora) {
        String normalizedRegion = groupValidator.normalizeAndValidate(regiao, "Regiao");
        String normalizedDistributor = groupValidator.normalizeAndValidate(distribuidora, "Distribuidora");
        BdgdImportRecord anterior = repository.find(id);
        if (!normalizedDistributor.equals(anterior.distribuidora())) {
            int ativos = assetService.countAssetsByDistribuidora(anterior.distribuidora());
            registrarAtivos(id, anterior.distribuidora(), ativos);
            log.warn("Importacao {} movida de '{}' para '{}'. Os ativos em bdgd.* ainda estao "
                    + "vinculados a '{}': reimporte a base para realinhar mapa e contagem.",
                    id, anterior.distribuidora(), normalizedDistributor, anterior.distribuidora());
        }
        repository.updateGroup(id, normalizedRegion, normalizedDistributor);
        return toSummary(repository.find(id));
    }

    private BdgdBaseSummaryResponse toSummary(BdgdImportRecord record) {
        int ativos = contarAtivos(record);
        String projecao = "SIRGAS 2000 / UTM 23S";
        return new BdgdBaseSummaryResponse(
                record.id(),
                record.distribuidora(),
                record.regiao(),
                record.data(),
                record.fileName(),
                record.status().name().toLowerCase(),
                ativos,
                projecao,
                record.createdAt(),
                record.errorMessage()
        );
    }

    private int contarAtivos(BdgdImportRecord record) {
        if (record.status() != BdgdImportStatus.CONCLUIDO) {
            return 0;
        }
        AtivosRegistrados registrados = ativosPorImport.get(record.id());
        if (registrados != null && !registrados.contagemExpirada()) {
            return registrados.quantidade();
        }
        int quantidade = assetService.countAssetsByImportId(record.id());
        if (quantidade == 0) {
            String distribuidora = (registrados != null)
                    ? registrados.distribuidoraNaImportacao()
                    : record.distribuidora();
            quantidade = assetService.countAssetsByDistribuidora(distribuidora);
        }
        registrarAtivos(record.id(), record.distribuidora(), quantidade);
        return quantidade;
    }

    private void registrarAtivos(UUID id, String distribuidora, int quantidade) {
        if (ativosPorImport.size() >= MAX_ATIVOS_REGISTROS) {
            Instant limite = Instant.now().minus(ATIVOS_REGISTRO_RETENCAO);
            ativosPorImport.values().removeIf(r -> r.calculadoEm().isBefore(limite));
        }
        ativosPorImport.put(id, new AtivosRegistrados(distribuidora, quantidade, Instant.now()));
    }

    public List<String> listRegions() {
        return repository.findRegions();
    }

    public List<String> listDistributors(String regiao) {
        String normalizedRegion = groupValidator.normalize(regiao);
        if (normalizedRegion == null) {
            return repository.findDistributors();
        }
        return repository.findDistributorsByRegion(normalizedRegion);
    }
}
