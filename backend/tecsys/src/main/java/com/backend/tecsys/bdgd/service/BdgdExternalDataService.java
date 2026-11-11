package com.backend.tecsys.bdgd.service;

import com.backend.tecsys.bdgd.model.BdgdImportOptionsResponse;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.text.Collator;
import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.CompletableFuture;

@Slf4j
@Service
public class BdgdExternalDataService {

    public static final String ANEEL_API_URL =
            "https://dadosabertos.aneel.gov.br/api/action/datastore_search?resource_id=64250fc9-4f7a-4d97-b0d4-3c090e005e1c&filters=%7B%22IdcDistribuicao%22%3A%221%22%2C%22IdcAtivo%22%3A%22A%22%7D&limit=300";

    private static final Duration CACHE_DURATION = Duration.ofHours(24);
    private static final Duration HTTP_TIMEOUT = Duration.ofSeconds(8);

    private static final Set<String> NON_ELECTRIC_SIGLAS = Set.of(
            "ANATEL", "ADASA", "ETENE", "EEVP",
            "VDB III", "ROSARIO", "BUIQUE", "GYBR X", "GYBR XIII",
            "SENTO SE VIII", "SENTO SE XI", "SENTO SE XIII", "SENTO SE XIV", "VSA VIII"
    );

    private static final List<String> NON_ELECTRIC_TERMS = List.of(
            "PARQUE SOLAR", "COMPLEXO SOLAR", "ENERGIA SOLAR", "FOTOVOLTAICA", "UFV",
            "VENTOS DE", "PARQUE EOLICO", "EOLICA", "EOLICO", "ENERGIAS RENOVAVEIS",
            "TRANSMISSORA", "TRANSMISSAO", "CONSTRUTORA", "CONSULTORIA",
            "INVESTIMENTOS", "PARTICIPACOES", "EMPREENDIMENTO ENERGETICO", "CONFEDERACAO",
            "AGENCIA REGULADORA", "AGENCIA NACIONAL", "BOQUEIRAO ENERGIA", "CANDEIAS ENERGIA",
            "SOLTEC BRASIL", "PHOENIX ENERGIAS"
    );

    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    private List<String> cachedDistributors = new ArrayList<>();
    private Instant lastFetch = Instant.EPOCH;

    public BdgdExternalDataService() {
        this(new ObjectMapper());
    }

    public BdgdExternalDataService(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(HTTP_TIMEOUT)
                .followRedirects(HttpClient.Redirect.NORMAL)
                .build();
    }

    @PostConstruct
    public void init() {
        loadFallbackData();
        refreshAsync();
    }

    public synchronized BdgdImportOptionsResponse getImportOptions() {
        if (isCacheExpired()) {
            refreshAsync();
        }
        return BdgdImportOptionsResponse.of(
                BdgdGroupValidator.ALLOWED_REGIONS,
                Collections.unmodifiableList(cachedDistributors)
        );
    }

    public List<String> getRegions() {
        return BdgdGroupValidator.ALLOWED_REGIONS;
    }

    public List<String> getDistributors() {
        return getImportOptions().distribuidoras();
    }

    private boolean isCacheExpired() {
        return Duration.between(lastFetch, Instant.now()).compareTo(CACHE_DURATION) >= 0;
    }

    public void refreshAsync() {
        CompletableFuture.runAsync(this::refreshData);
    }

    public synchronized void refreshData() {
        try {
            List<String> distributors = fetchDistributorsFromAneel();
            if (distributors != null && !distributors.isEmpty()) {
                this.cachedDistributors = distributors;
            }
        } catch (Exception e) {
            log.warn("Nao foi possivel atualizar distribuidoras da ANEEL (usando cache local): {}", e.getMessage());
        }
        this.lastFetch = Instant.now();
    }

    private List<String> fetchDistributorsFromAneel() {
        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(ANEEL_API_URL))
                    .timeout(HTTP_TIMEOUT)
                    .header("Accept", "application/json")
                    .header("User-Agent", "Mozilla/5.0")
                    .GET()
                    .build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 200) {
                return parseAneelDistributors(response.body());
            }
        } catch (Exception e) {
            log.debug("Falha na requisicao HTTP a ANEEL: {}", e.getMessage());
        }
        return null;
    }

    public List<String> parseAneelDistributors(String json) {
        try {
            JsonNode root = objectMapper.readTree(json);
            JsonNode records = root.path("result").path("records");
            if (records.isArray()) {
                Set<String> names = new LinkedHashSet<>();
                for (JsonNode r : records) {
                    String idcDist = r.path("IdcDistribuicao").asText("");
                    String idcAtivo = r.path("IdcAtivo").asText("");
                    if (!"1".equals(idcDist) || !"A".equalsIgnoreCase(idcAtivo)) {
                        continue;
                    }
                    String sigla = r.path("SigPessoa").asText("").strip();
                    String razao = r.path("NomRazaoSocial").asText("").strip();

                    if (!isElectricDistributor(sigla, razao)) {
                        continue;
                    }

                    if (!sigla.isEmpty()) {
                        names.add(sigla);
                    } else if (!razao.isEmpty()) {
                        names.add(razao);
                    }
                }
                List<String> sorted = new ArrayList<>(names);
                sorted.sort(Collator.getInstance(Locale.forLanguageTag("pt-BR")));
                return sorted;
            }
        } catch (Exception e) {
            log.error("Erro ao analisar JSON da ANEEL", e);
        }
        return null;
    }

    private boolean isElectricDistributor(String sigla, String razao) {
        if (sigla != null && NON_ELECTRIC_SIGLAS.contains(sigla.toUpperCase(Locale.ROOT).strip())) {
            return false;
        }
        if (razao != null) {
            String upper = razao.toUpperCase(Locale.ROOT);
            for (String term : NON_ELECTRIC_TERMS) {
                if (upper.contains(term)) {
                    return false;
                }
            }
        }
        return true;
    }

    public void loadFallbackData() {
        try {
            ClassPathResource aneelResource = new ClassPathResource("aneel_distribuidoras.json");
            if (aneelResource.exists()) {
                try (InputStream is = aneelResource.getInputStream()) {
                    List<String> distributors = parseAneelDistributors(new String(is.readAllBytes()));
                    if (distributors != null && !distributors.isEmpty()) {
                        this.cachedDistributors = distributors;
                    }
                }
            }
        } catch (Exception e) {
            log.warn("Erro ao carregar fallback de distribuidoras da ANEEL", e);
        }
    }
}
