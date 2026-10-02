package com.backend.tecsys;

import com.backend.tecsys.auth.dto.LoginRequest;
import com.backend.tecsys.scenario.dto.SimulationRequest;
import com.backend.tecsys.scenario.dto.GatewayCandidateRequest;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import java.util.List;

import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@ActiveProfiles("mock")
class SimulationIntegrationTest {

    @Autowired
    private WebApplicationContext context;

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
    }

    @Test
    void shouldAcceptValidSimulationRequest() throws Exception {
        mockMvc.perform(post("/simulations")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.scenarioId").isNumber())
                .andExpect(jsonPath("$.status").value("concluido"))
                .andExpect(jsonPath("$.selectedGateways").isArray())
                .andExpect(jsonPath("$.usedGatewayCount").isNumber())
                .andExpect(jsonPath("$.totalCoveragePct").isNumber())
                .andExpect(jsonPath("$.processingTimeMs").isNumber())
                .andExpect(jsonPath("$.propagationModel").value("OKUMURA_HATA_SUBURBAN"));
    }

    @Test
    void shouldRejectCoverageBelowMinimum() throws Exception {
        SimulationRequest request = validRequest();
        request.setCoverageTargetPct(0.5);

        mockMvc.perform(post("/simulations")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldRejectCoverageAboveMaximum() throws Exception {
        SimulationRequest request = validRequest();
        request.setCoverageTargetPct(150.0);

        mockMvc.perform(post("/simulations")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldRejectZeroGateways() throws Exception {
        SimulationRequest request = validRequest();
        request.setMaxGateways(0);

        mockMvc.perform(post("/simulations")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldRejectEmptyGatewayCandidates() throws Exception {
        SimulationRequest request = validRequest();
        request.setGatewayCandidates(List.of());

        mockMvc.perform(post("/simulations")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldRejectInvalidRfParameter() throws Exception {
        SimulationRequest request = validRequest();
        request.setFrequencyMhz(-10.0);

        mockMvc.perform(post("/simulations")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldRejectUnsupportedPropagationModel() throws Exception {
        SimulationRequest request = validRequest();
        request.setPropagationModel("MODELO_INEXISTENTE");

        mockMvc.perform(post("/simulations")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldReturnClearErrorWhenItmTerrainIsUnavailable() throws Exception {
        SimulationRequest request = validRequest();
        request.setPropagationModel("ITM_LONGLEY_RICE");

        mockMvc.perform(post("/simulations")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnprocessableContent())
                .andExpect(jsonPath("$.error").isNotEmpty());
    }

    @Test
    void shouldPersistScenarioSelectedGatewaysAndIndicators() throws Exception {
        MvcResult result = mockMvc.perform(post("/simulations")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.scenarioId").isNumber())
                .andExpect(jsonPath("$.coveredAssetKeys").isArray())
                .andExpect(jsonPath("$.coveragePctByAssetType").isMap())
                .andExpect(jsonPath("$.totalEstimatedCost").isNumber())
                .andReturn();

        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        org.junit.jupiter.api.Assertions.assertTrue(body.get("scenarioId").asLong() > 0);
        org.junit.jupiter.api.Assertions.assertTrue(body.get("coveredAssetKeys").size() > 0);
    }

    @Test
    void shouldUseSearchAreaAsAssetUniverse() throws Exception {
        // Raio de 50 m em volta do ASSET-1 do mock (-22.0, -47.0): só ele está dentro.
        SimulationRequest request = validRequest();
        request.setSearchCenterLatitude(-22.0000);
        request.setSearchCenterLongitude(-47.0000);
        request.setSearchRadiusMeters(50.0);

        MvcResult result = mockMvc.perform(post("/simulations")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        int universe = body.get("coveredAssetKeys").size() + body.get("uncoveredAssetKeys").size();
        org.junit.jupiter.api.Assertions.assertEquals(1, universe);
        org.junit.jupiter.api.Assertions.assertEquals(100.0, body.get("totalCoveragePct").asDouble(), 0.001);
        org.junit.jupiter.api.Assertions.assertTrue(body.get("targetReached").asBoolean());
    }

    @Test
    void shouldRejectSearchAreaWithoutAnyAssets() throws Exception {
        SimulationRequest request = validRequest();
        request.setSearchCenterLatitude(10.0);
        request.setSearchCenterLongitude(10.0);
        request.setSearchRadiusMeters(100.0);

        mockMvc.perform(post("/simulations")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldRejectPartialSearchArea() throws Exception {
        SimulationRequest request = validRequest();
        request.setSearchCenterLatitude(-22.0000);
        request.setSearchCenterLongitude(-47.0000);

        mockMvc.perform(post("/simulations")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
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

    private SimulationRequest validRequest() {
        return SimulationRequest.builder()
                .name("Cenário Centro")
                .regionName("Centro")
                .coverageTargetPct(90.0)
                .maxGateways(5)
                .gatewayCandidates(List.of(
                        candidate(1L, -22.0000, -47.0000),
                        candidate(2L, -22.0000, -46.9950),
                        candidate(3L, -22.0000, -46.9900),
                        candidate(4L, -22.0050, -47.0000),
                        candidate(5L, -22.0050, -46.9950)))
                .propagationModel("OKUMURA_HATA_SUBURBAN")
                .build();
    }

    private GatewayCandidateRequest candidate(Long id, double latitude, double longitude) {
        return GatewayCandidateRequest.builder()
                .id(id)
                .source("API de delimitação da área de busca")
                .assetKey("CANDIDATE-" + id)
                .latitude(latitude)
                .longitude(longitude)
                .estimatedCost(1500.0)
                .build();
    }
}
