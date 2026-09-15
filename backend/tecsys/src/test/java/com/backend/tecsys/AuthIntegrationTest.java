package com.backend.tecsys;

import com.backend.tecsys.presentation.dto.LoginRequest;
import com.backend.tecsys.presentation.dto.RefreshTokenRequest;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@ActiveProfiles("mock")
class AuthIntegrationTest {

    @Autowired
    private WebApplicationContext context;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders
                .webAppContextSetup(context)
                .apply(springSecurity())
                .build();
    }

    @Test
    void shouldLoginSuccessfullyAndReturnTokensAndRole() throws Exception {
        LoginRequest request = new LoginRequest("admin@tecsys.com", "Admin@123");

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.refreshToken").isNotEmpty())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.expiresIn").isNumber())
                .andExpect(jsonPath("$.user.email").value("admin@tecsys.com"))
                .andExpect(jsonPath("$.user.role").value("ADMIN"));
    }

    @Test
    void shouldFailLoginWithIncorrectPassword() throws Exception {
        LoginRequest request = new LoginRequest("admin@tecsys.com", "SenhaErrada");

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("E-mail ou senha inválidos."));
    }

    @Test
    void shouldAccessProtectedEndpointWithToken() throws Exception {
        LoginRequest loginRequest = new LoginRequest("admin@tecsys.com", "Admin@123");
        MvcResult loginResult = mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode loginJson = objectMapper.readTree(loginResult.getResponse().getContentAsString());
        String token = loginJson.get("token").asText();

        mockMvc.perform(get("/auth/me")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("admin@tecsys.com"))
                .andExpect(jsonPath("$.role").value("ADMIN"));
    }

    @Test
    void shouldRejectProtectedEndpointWhenTokenIsMissing() throws Exception {
        mockMvc.perform(get("/auth/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
    }

    @Test
    void shouldRejectProtectedEndpointWhenTokenIsInvalid() throws Exception {
        mockMvc.perform(get("/auth/me")
                        .header("Authorization", "Bearer token_completamente_invalido"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("TOKEN_INVALID"));
    }

    @Test
    void shouldRefreshTokenSuccessfullyAndRotate() throws Exception {
        LoginRequest loginRequest = new LoginRequest("operador@distribuidora.com.br", "Oper@456");
        MvcResult loginResult = mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode loginJson = objectMapper.readTree(loginResult.getResponse().getContentAsString());
        String refreshToken = loginJson.get("refreshToken").asText();

        RefreshTokenRequest refreshReq = new RefreshTokenRequest(refreshToken);
        MvcResult refreshResult = mockMvc.perform(post("/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(refreshReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.refreshToken").isNotEmpty())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andReturn();

        JsonNode refreshJson = objectMapper.readTree(refreshResult.getResponse().getContentAsString());
        String newAccessToken = refreshJson.get("accessToken").asText();

        mockMvc.perform(get("/auth/me")
                        .header("Authorization", "Bearer " + newAccessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("operador@distribuidora.com.br"));

        mockMvc.perform(post("/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new RefreshTokenRequest(refreshToken))))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldLogoutAndRevokeRefreshToken() throws Exception {
        LoginRequest loginRequest = new LoginRequest("admin@tecsys.com", "Admin@123");
        MvcResult loginResult = mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode loginJson = objectMapper.readTree(loginResult.getResponse().getContentAsString());
        String accessToken = loginJson.get("token").asText();
        String refreshToken = loginJson.get("refreshToken").asText();

        mockMvc.perform(post("/auth/logout")
                        .header("Authorization", "Bearer " + accessToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new RefreshTokenRequest(refreshToken))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Logout realizado com sucesso"));

        mockMvc.perform(post("/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new RefreshTokenRequest(refreshToken))))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldRejectLoginWithBlankEmailOrPassword() throws Exception {
        LoginRequest request = new LoginRequest("", "");

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.fields.email").isNotEmpty())
                .andExpect(jsonPath("$.fields.password").isNotEmpty());
    }

    @Test
    void shouldRejectLoginWithInvalidEmailFormat() throws Exception {
        LoginRequest request = new LoginRequest("not-an-email", "Pass123");

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.fields.email").value("Formato de e-mail inválido."));
    }

    @Test
    void shouldRejectRefreshWithBlankRefreshToken() throws Exception {
        RefreshTokenRequest request = new RefreshTokenRequest("");

        mockMvc.perform(post("/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.fields.refreshToken").value("O refresh token é obrigatório."));
    }
}

