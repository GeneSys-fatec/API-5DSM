package com.backend.tecsys;

import com.backend.tecsys.auth.dto.LoginRequest;
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

import java.sql.Date;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;

import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.not;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@ActiveProfiles("mock")
class BdgdGroupingIntegrationTest {

    private static final String REGION_A = "Regiao Teste Alfa";
    private static final String REGION_B = "Regiao Teste Beta";
    private static final String DIST_A1 = "Distribuidora Alfa 1";
    private static final String DIST_A2 = "Distribuidora Alfa 2";
    private static final String DIST_B1 = "Distribuidora Beta 1";
    private static final String NUL = String.valueOf((char) 0);

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private JdbcTemplate jdbc;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private MockMvc mockMvc;
    private String token;
    private String distA1Id;

    @BeforeEach
    void setUp() throws Exception {
        mockMvc = MockMvcBuilders
                .webAppContextSetup(context)
                .apply(springSecurity())
                .build();
        token = loginAsAdmin();

        jdbc.update("DELETE FROM bdgd_imports");
        distA1Id = insertImport(REGION_A, DIST_A1);
        insertImport(REGION_A, DIST_A2);
        insertImport(REGION_B, DIST_B1);
    }

    @Test
    void shouldListDistinctRegions() throws Exception {
        mockMvc.perform(get("/api/bdgd/regions")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasItem(REGION_A)))
                .andExpect(jsonPath("$", hasItem(REGION_B)));
    }

    @Test
    void shouldListAllDistributorsWhenRegionOmitted() throws Exception {
        mockMvc.perform(get("/api/bdgd/distributors")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasItem(DIST_A1)))
                .andExpect(jsonPath("$", hasItem(DIST_A2)))
                .andExpect(jsonPath("$", hasItem(DIST_B1)));
    }

    @Test
    void shouldListOnlyDistributorsOfSelectedRegion() throws Exception {
        mockMvc.perform(get("/api/bdgd/distributors")
                        .param("regiao", REGION_A)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasItem(DIST_A1)))
                .andExpect(jsonPath("$", hasItem(DIST_A2)))
                .andExpect(jsonPath("$", not(hasItem(DIST_B1))));
    }

    @Test
    void shouldFilterBasesByRegionAndDistributor() throws Exception {
        mockMvc.perform(get("/api/bdgd/bases")
                        .param("regiao", REGION_A)
                        .param("distribuidora", DIST_A1)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].regiao").value(REGION_A))
                .andExpect(jsonPath("$[0].distribuidora").value(DIST_A1));
    }

    @Test
    void shouldReturnEmptyListForUnknownRegion() throws Exception {
        mockMvc.perform(get("/api/bdgd/bases")
                        .param("regiao", "Regiao Inexistente")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void shouldReturnEmptyDistributorsForUnknownRegion() throws Exception {
        mockMvc.perform(get("/api/bdgd/distributors")
                        .param("regiao", "Regiao Inexistente")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void shouldMatchStoredGroupWhenFilteringWithUntrimmedValue() throws Exception {
        mockMvc.perform(get("/api/bdgd/bases")
                        .param("regiao", "  " + REGION_A + "  ")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)));

        mockMvc.perform(get("/api/bdgd/distributors")
                        .param("regiao", " " + REGION_B + " ")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", contains(DIST_B1)));
    }

    @Test
    void shouldMoveBaseToAnotherGroup() throws Exception {
        String body = objectMapper.writeValueAsString(Map.of("regiao", REGION_B, "distribuidora", DIST_B1));

        mockMvc.perform(patch("/api/bdgd/" + distA1Id)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.regiao").value(REGION_B))
                .andExpect(jsonPath("$.distribuidora").value(DIST_B1));

        mockMvc.perform(get("/api/bdgd/bases")
                        .param("regiao", REGION_A)
                        .param("distribuidora", DIST_A1)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void shouldRejectBlankGroupFields() throws Exception {
        String body = objectMapper.writeValueAsString(Map.of("regiao", "  ", "distribuidora", DIST_B1));

        mockMvc.perform(patch("/api/bdgd/" + distA1Id)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldPersistGroupFieldsTrimmed() throws Exception {
        String body = objectMapper.writeValueAsString(
                Map.of("regiao", "  " + REGION_B + "  ", "distribuidora", "  " + DIST_B1 + "  "));

        mockMvc.perform(patch("/api/bdgd/" + distA1Id)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.regiao").value(REGION_B))
                .andExpect(jsonPath("$.distribuidora").value(DIST_B1));

        assertEquals(REGION_B, jdbc.queryForObject(
                "SELECT regiao FROM bdgd_imports WHERE id = ?", String.class, distA1Id));
    }

    @Test
    void shouldRejectGroupFieldsLongerThanColumnLimit() throws Exception {
        String body = objectMapper.writeValueAsString(
                Map.of("regiao", REGION_B, "distribuidora", "D".repeat(121)));

        mockMvc.perform(patch("/api/bdgd/" + distA1Id)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldRejectControlCharactersInGroupFields() throws Exception {
        String body = objectMapper.writeValueAsString(
                Map.of("regiao", "Regiao" + NUL + "Invalida", "distribuidora", DIST_B1));

        mockMvc.perform(patch("/api/bdgd/" + distA1Id)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldNotPersistGroupFieldsWhenValidationFails() throws Exception {
        String body = objectMapper.writeValueAsString(
                Map.of("regiao", REGION_B, "distribuidora", "D".repeat(121)));

        mockMvc.perform(patch("/api/bdgd/" + distA1Id)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest());

        assertEquals(DIST_A1, jdbc.queryForObject(
                "SELECT distribuidora FROM bdgd_imports WHERE id = ?", String.class, distA1Id));
    }

    @Test
    void shouldReturnNotFoundWhenUpdatingUnknownImport() throws Exception {
        String body = objectMapper.writeValueAsString(Map.of("regiao", REGION_B, "distribuidora", DIST_B1));

        mockMvc.perform(patch("/api/bdgd/" + UUID.randomUUID())
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldAllowPatchInCorsPreflight() throws Exception {
        mockMvc.perform(options("/api/bdgd/" + distA1Id)
                        .header("Origin", "http://localhost:3000")
                        .header("Access-Control-Request-Method", "PATCH"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Methods", containsString("PATCH")));
    }

    private String insertImport(String regiao, String distribuidora) {
        String id = UUID.randomUUID().toString();
        jdbc.update("INSERT INTO bdgd_imports (id, distribuidora, regiao, data_referencia, file_name, storage_key, status, error_message, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                id, distribuidora, regiao, Date.valueOf(LocalDate.of(2024, 3, 1)),
                "base.zip", "key/base.zip", "CONCLUIDO", null, Timestamp.from(Instant.now()));
        return id;
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
