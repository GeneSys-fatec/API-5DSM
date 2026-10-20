package com.backend.tecsys.bdgd;

import com.backend.tecsys.auth.dto.LoginRequest;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@ActiveProfiles("mock")
public class BdgdIngestionPostmanIntegrationTest {

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

    @Test
    @DisplayName("Postman 1: GET /api/bdgd/template/csv deve baixar modelo CSV")
    void shouldDownloadCsvTemplate() throws Exception {
        MvcResult result = mockMvc.perform(get("/api/bdgd/template/csv")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Disposition", "attachment; filename=\"exemplo_ativos_bdgd.csv\""))
                .andReturn();

        String content = result.getResponse().getContentAsString();
        assertTrue(content.contains("identificador"));
        assertTrue(content.contains("tipo_ativo"));
        assertTrue(content.contains("latitude"));
        assertTrue(content.contains("longitude"));
    }

    @Test
    @DisplayName("Postman 2: GET /api/bdgd/template/xlsx deve baixar modelo Excel")
    void shouldDownloadXlsxTemplate() throws Exception {
        mockMvc.perform(get("/api/bdgd/template/xlsx")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Disposition", "attachment; filename=\"exemplo_ativos_bdgd.xlsx\""));
    }

    @Test
    @DisplayName("Postman 3: GET /api/bdgd/template/json deve baixar modelo JSON")
    void shouldDownloadJsonTemplate() throws Exception {
        MvcResult result = mockMvc.perform(get("/api/bdgd/template/json")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Disposition", "attachment; filename=\"exemplo_ativos_bdgd.json\""))
                .andReturn();

        String content = result.getResponse().getContentAsString();
        assertTrue(content.contains("identificador"));
        assertTrue(content.contains("POSTE"));
    }

    @Test
    @DisplayName("Postman 4: POST /api/bdgd/upload com CSV válido deve retornar 202 com importId")
    void shouldUploadValidCsv() throws Exception {
        String csvContent = """
                identificador,tipo_ativo,latitude,longitude,distribuidora,regiao
                POSTE-01,POSTE,-23.550520,-46.633308,ENEL,SP
                SUB-01,SUBESTACAO,-23.551000,-46.634000,ENEL,SP
                """;

        MockMultipartFile file = new MockMultipartFile(
                "file", "ativos.csv", "text/csv", csvContent.getBytes(StandardCharsets.UTF_8));

        mockMvc.perform(multipart("/api/bdgd/upload")
                        .file(file)
                        .param("distribuidora", "ENEL")
                        .param("regiao", "SP")
                        .param("data", "2026-10-18")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.importId").isNotEmpty())
                .andExpect(jsonPath("$.distribuidora").value("ENEL"));
    }

    @Test
    @DisplayName("Postman 5: POST /api/bdgd/upload com JSON válido deve retornar 202 com importId")
    void shouldUploadValidJson() throws Exception {
        String jsonContent = """
                [
                  {"identificador": "POS-J1", "tipo_ativo": "POSTE", "latitude": -23.55, "longitude": -46.63},
                  {"identificador": "UC-J1", "tipo_ativo": "UCBT", "latitude": -23.56, "longitude": -46.64}
                ]
                """;

        MockMultipartFile file = new MockMultipartFile(
                "file", "ativos.json", "application/json", jsonContent.getBytes(StandardCharsets.UTF_8));

        mockMvc.perform(multipart("/api/bdgd/upload")
                        .file(file)
                        .param("distribuidora", "CPFL")
                        .param("regiao", "CAMPINAS")
                        .param("data", "2026-10-18")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.importId").isNotEmpty())
                .andExpect(jsonPath("$.distribuidora").value("CPFL"));
    }

    @Test
    @DisplayName("Postman 5b: POST /api/bdgd/upload com ZIP contendo CSV e JSON válidos deve retornar 202 com importId")
    void shouldUploadValidZipWithTabularData() throws Exception {
        java.io.ByteArrayOutputStream baos = new java.io.ByteArrayOutputStream();
        try (java.util.zip.ZipOutputStream zos = new java.util.zip.ZipOutputStream(baos)) {
            zos.putNextEntry(new java.util.zip.ZipEntry("ativos.csv"));
            String csv = "identificador,tipo_ativo,latitude,longitude\nPOS-ZIP-1,POSTE,-23.55,-46.63\n";
            zos.write(csv.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();
        }

        MockMultipartFile file = new MockMultipartFile(
                "file", "ativos_tabular.zip", "application/zip", baos.toByteArray());

        mockMvc.perform(multipart("/api/bdgd/upload")
                        .file(file)
                        .param("distribuidora", "CPFL")
                        .param("regiao", "CAMPINAS")
                        .param("data", "2026-10-18")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.importId").isNotEmpty())
                .andExpect(jsonPath("$.distribuidora").value("CPFL"));
    }

    @Test
    @DisplayName("Postman 6: POST /api/bdgd/upload com CSV com latitude inválida deve atualizar status para falhou com linha de erro")
    void shouldRejectInvalidCsvWithLineError() throws Exception {
        String invalidCsv = """
                identificador,tipo_ativo,latitude,longitude
                POS-1,POSTE,-23.55,-46.63
                POS-2,POSTE,INVALID_LAT,-46.63
                """;

        MockMultipartFile file = new MockMultipartFile(
                "file", "invalid.csv", "text/csv", invalidCsv.getBytes(StandardCharsets.UTF_8));

        MvcResult result = mockMvc.perform(multipart("/api/bdgd/upload")
                        .file(file)
                        .param("distribuidora", "CPFL")
                        .param("regiao", "CAMPINAS")
                        .param("data", "2026-10-18")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isAccepted())
                .andReturn();

        JsonNode response = objectMapper.readTree(result.getResponse().getContentAsString());
        String importId = response.get("importId").asText();

        // Aguarda brevemente o processamento assíncrono
        Thread.sleep(300);

        mockMvc.perform(get("/api/bdgd/" + importId)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("falhou"))
                .andExpect(jsonPath("$.errorMessage").value(org.hamcrest.Matchers.containsString("linha 3")))
                .andExpect(jsonPath("$.errorMessage").value(org.hamcrest.Matchers.containsString("latitude")));
    }

    @Test
    @DisplayName("Postman 7: GET /api/bdgd/bases deve listar bases cadastradas")
    void shouldListBases() throws Exception {
        mockMvc.perform(get("/api/bdgd/bases")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    @Test
    @DisplayName("Postman 8: GET /api/bdgd/map?layer=POSTE deve retornar FeatureCollection GeoJSON")
    void shouldQueryMapLayer() throws Exception {
        mockMvc.perform(get("/api/bdgd/map")
                        .param("layer", "POSTE")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.type").value("FeatureCollection"))
                .andExpect(jsonPath("$.features").isArray());
    }
}
