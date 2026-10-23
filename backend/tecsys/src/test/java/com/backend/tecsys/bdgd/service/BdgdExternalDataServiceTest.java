package com.backend.tecsys.bdgd.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class BdgdExternalDataServiceTest {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private BdgdExternalDataService service;

    @BeforeEach
    void setUp() {
        service = new BdgdExternalDataService(objectMapper);
    }

    @Test
    void shouldReturnFixedBrazilianRegionsWithoutExternalApi() {
        List<String> regions = service.getRegions();
        assertNotNull(regions);
        assertEquals(5, regions.size());
        assertTrue(regions.contains("Centro-Oeste"));
        assertTrue(regions.contains("Nordeste"));
        assertTrue(regions.contains("Norte"));
        assertTrue(regions.contains("Sudeste"));
        assertTrue(regions.contains("Sul"));
    }

    @Test
    void shouldParseAneelDistributorsFilteringActiveAndDistributionOnly() {
        String json = """
                {
                    "result": {
                        "records": [
                            {
                                "IdcDistribuicao": "1",
                                "IdcAtivo": "A",
                                "SigPessoa": "CPFL-PAULISTA",
                                "NomRazaoSocial": "CPFL PAULISTA S.A"
                            },
                            {
                                "IdcDistribuicao": "1",
                                "IdcAtivo": "A",
                                "SigPessoa": "",
                                "NomRazaoSocial": "COOPERATIVA ENERGETICA EXEMPLO"
                            },
                            {
                                "IdcDistribuicao": "0",
                                "IdcAtivo": "A",
                                "SigPessoa": "GERADORA X",
                                "NomRazaoSocial": "GERADORA X S.A"
                            },
                            {
                                "IdcDistribuicao": "1",
                                "IdcAtivo": "I",
                                "SigPessoa": "INATIVA D",
                                "NomRazaoSocial": "INATIVA DISTRIBUIDORA"
                            }
                        ]
                    }
                }
                """;

        List<String> distributors = service.parseAneelDistributors(json);

        assertNotNull(distributors);
        assertTrue(distributors.contains("CPFL-PAULISTA"));
        assertTrue(distributors.contains("COOPERATIVA ENERGETICA EXEMPLO"));
        assertFalse(distributors.contains("GERADORA X"));
        assertFalse(distributors.contains("INATIVA D"));
    }

    @Test
    void shouldLoadFallbackDataFromClasspathResources() {
        service.loadFallbackData();

        List<String> regions = service.getRegions();
        assertNotNull(regions);
        assertEquals(5, regions.size());
        assertTrue(regions.contains("Sudeste"));

        List<String> distributors = service.getDistributors();
        assertNotNull(distributors);
        assertTrue(distributors.size() >= 100);
        assertTrue(distributors.contains("CPFL-PAULISTA"));
    }

    @Test
    void validatorWithExternalDataServiceShouldRecognizeAneelDistributors() {
        service.loadFallbackData();
        BdgdGroupValidator validator = new BdgdGroupValidator(service);

        assertDoesNotThrow(() -> validator.validateAndNormalizeDistributor("CPFL-PAULISTA"));
        assertDoesNotThrow(() -> validator.validateAndNormalizeDistributor("CEMIG-D"));
        assertDoesNotThrow(() -> validator.validateAndNormalizeRegion("Sudeste"));
    }

    @Test
    void shouldFetchDistributorsDirectlyFromLiveAneelApi() {
        BdgdExternalDataService liveService = new BdgdExternalDataService(objectMapper);
        assertEquals(0, liveService.getDistributors().size(), "Antes do refresh, a lista deve estar vazia");

        liveService.refreshData();

        List<String> distributors = liveService.getDistributors();
        org.junit.jupiter.api.Assumptions.assumeTrue(
                !distributors.isEmpty(),
                "Ambiente offline ou portal da ANEEL indisponivel no momento do teste"
        );
        assertTrue(distributors.size() >= 100);
        assertTrue(distributors.contains("CPFL-PAULISTA"));
        assertTrue(distributors.contains("CEMIG-D"));
    }
}
