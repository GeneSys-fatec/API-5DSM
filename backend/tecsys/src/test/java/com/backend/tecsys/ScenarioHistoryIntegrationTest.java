package com.backend.tecsys;

import com.backend.tecsys.auth.dto.LoginRequest;
import com.backend.tecsys.auth.model.User;
import com.backend.tecsys.auth.repository.IUserRepository;
import com.backend.tecsys.scenario.dto.GatewayCandidateRequest;
import com.backend.tecsys.scenario.dto.SimulationRequest;
import com.backend.tecsys.scenario.model.Scenario;
import com.backend.tecsys.scenario.repository.IScenarioRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import java.util.List;
import java.util.UUID;

import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@ActiveProfiles("mock")
class ScenarioHistoryIntegrationTest {

    private static final UUID TEST_IMPORT_ID = UUID.randomUUID();

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private IScenarioRepository scenarioRepository;

    @Autowired
    private IUserRepository userRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private MockMvc mockMvc;
    private String token;

    @BeforeEach
    void setUp() throws Exception {
        mockMvc = MockMvcBuilders
                .webAppContextSetup(context)
                .apply(springSecurity())
                .build();
        token = loginAsAdmin();
        jdbcTemplate.update("DELETE FROM bdgd_imports WHERE id = ?", TEST_IMPORT_ID.toString());
        jdbcTemplate.update("INSERT INTO bdgd_imports "
                        + "(id, distribuidora, regiao, data_referencia, file_name, storage_key, status, created_at) "
                        + "VALUES (?, 'TESTE', 'TESTE', CURRENT_DATE, 'teste.gdb', 'teste-key', 'CONCLUIDO', CURRENT_TIMESTAMP)",
                TEST_IMPORT_ID.toString());
    }

    @Test
    void shouldPersistUpdatedScenarioNameAndReturnItInHistoryListing() throws Exception {
        SimulationRequest request = SimulationRequest.builder()
                .importId(TEST_IMPORT_ID)
                .name("Cenário Inicial")
                .regionName("Centro")
                .coverageTargetPct(90.0)
                .maxGateways(5)
                .gatewayCandidates(List.of(
                        GatewayCandidateRequest.builder()
                                .id(1L)
                                .source("API")
                                .assetKey("CANDIDATE-1")
                                .latitude(-22.0)
                                .longitude(-47.0)
                                .estimatedCost(1500.0)
                                .build()))
                .propagationModel("OKUMURA_HATA_SUBURBAN")
                .build();

        MvcResult simResult = mockMvc.perform(post("/simulations")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.scenarioName").value("Cenário Inicial"))
                .andReturn();

        long scenarioId = objectMapper.readTree(simResult.getResponse().getContentAsString())
                .get("scenarioId").asLong();

        mockMvc.perform(patch("/scenarios/" + scenarioId)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\": \"  Cenário Salvo Histórico  \", \"regionName\": \"Campinas - SP\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(scenarioId))
                .andExpect(jsonPath("$.name").value("Cenário Salvo Histórico"))
                .andExpect(jsonPath("$.regionName").value("Campinas - SP"));

        mockMvc.perform(get("/scenarios")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.id == " + scenarioId + ")].name", hasItem("Cenário Salvo Histórico")))
                .andExpect(jsonPath("$[?(@.id == " + scenarioId + ")].regionName", hasItem("Campinas - SP")));

        mockMvc.perform(get("/scenarios/" + scenarioId)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Cenário Salvo Histórico"))
                .andExpect(jsonPath("$.regionName").value("Campinas - SP"));
    }

    @Test
    void shouldRejectBlankNameAndReturnNotFoundForUnknownScenario() throws Exception {
        mockMvc.perform(patch("/scenarios/999999")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\": \"Cenário Válido\"}"))
                .andExpect(status().isNotFound());

        mockMvc.perform(patch("/scenarios/1")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\": \"   \"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldHandlePreviouslySavedScenarioWithoutNameAndAllowRenaming() throws Exception {
        User admin = userRepository.findByEmail("admin@tecsys.com").orElseThrow();
        Scenario legacy = scenarioRepository.save(Scenario.builder()
                .name(null)
                .userId(admin.getId())
                .utilityId(admin.getUtilityId())
                .regionName("Região Legada")
                .coverageTargetPct(85.0)
                .maxGateways(3)
                .status("concluido")
                .build());

        mockMvc.perform(get("/scenarios")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.id == " + legacy.getId() + ")].name", hasItem(nullValue())));

        mockMvc.perform(patch("/scenarios/" + legacy.getId())
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\": \"Cenário Legado Nomeado\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Cenário Legado Nomeado"))
                .andExpect(jsonPath("$.regionName").value("Região Legada"));
    }

    private String loginAsAdmin() throws Exception {
        LoginRequest login = new LoginRequest("admin@tecsys.com", "Admin@123");
        MvcResult result = mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(login)))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        return body.get("token").asText();
    }
}

