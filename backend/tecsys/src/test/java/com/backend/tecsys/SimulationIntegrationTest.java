package com.backend.tecsys;

import com.backend.tecsys.presentation.dto.LoginRequest;
import com.backend.tecsys.presentation.dto.SimulationRequest;
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
                .propagationModel("OKUMURA_HATA_SUBURBAN")
                .build();
    }
}
