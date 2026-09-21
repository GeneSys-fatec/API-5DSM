package com.backend.tecsys;

import com.backend.tecsys.auth.dto.CreateUserRequest;
import com.backend.tecsys.auth.dto.LoginRequest;
import com.backend.tecsys.auth.dto.UpdateUserRequest;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@ActiveProfiles("mock")
class UserCrudIntegrationTest {

    @Autowired
    private WebApplicationContext context;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private MockMvc mockMvc;
    private String adminToken;

    @BeforeEach
    void setUp() throws Exception {
        mockMvc = MockMvcBuilders
                .webAppContextSetup(context)
                .apply(springSecurity())
                .build();

        LoginRequest loginRequest = new LoginRequest("admin@tecsys.com", "Admin@123");
        MvcResult result = mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
        adminToken = json.get("token").asText();
    }

    @Test
    void shouldCreateUserSuccessfully() throws Exception {
        CreateUserRequest request = CreateUserRequest.builder()
                .nome("Novo Usuario Teste")
                .email("novo.usuario@tecsys.com")
                .senha("Senha@123")
                .confirmarSenha("Senha@123")
                .build();

        mockMvc.perform(post("/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.nome").value("Novo Usuario Teste"))
                .andExpect(jsonPath("$.email").value("novo.usuario@tecsys.com"))
                .andExpect(jsonPath("$.role").value("ENGENHEIRO"))
                .andExpect(jsonPath("$.password").doesNotExist())
                .andExpect(jsonPath("$.senha").doesNotExist())
                .andExpect(jsonPath("$.senha_hash").doesNotExist())
                .andExpect(jsonPath("$.passwordHash").doesNotExist())
                .andExpect(jsonPath("$.token").doesNotExist());
    }

    @Test
    void shouldFailWhenPasswordsDoNotMatch() throws Exception {
        CreateUserRequest request = CreateUserRequest.builder()
                .nome("Usuario Mismatch")
                .email("mismatch@tecsys.com")
                .senha("Senha@123")
                .confirmarSenha("SenhaDiferente@123")
                .build();

        mockMvc.perform(post("/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").isNotEmpty());
    }

    @Test
    void shouldFailWhenEmailAlreadyExists() throws Exception {
        CreateUserRequest request = CreateUserRequest.builder()
                .nome("Admin Duplicado")
                .email("admin@tecsys.com")
                .senha("Senha@123")
                .confirmarSenha("Senha@123")
                .build();

        mockMvc.perform(post("/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("O e-mail informado já está cadastrado."));
    }

    @Test
    void shouldFailWhenEmailIsInvalid() throws Exception {
        CreateUserRequest request = CreateUserRequest.builder()
                .nome("Email Invalido")
                .email("email-sem-formato-correto")
                .senha("Senha@123")
                .confirmarSenha("Senha@123")
                .build();

        mockMvc.perform(post("/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldRejectListUsersWithoutAuthentication() throws Exception {
        mockMvc.perform(get("/users"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldListUsersWhenAuthenticated() throws Exception {
        mockMvc.perform(get("/users")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0].email").value("admin@tecsys.com"))
                .andExpect(jsonPath("$[0].password").doesNotExist());
    }

    @Test
    void shouldGetUserByIdSuccessfully() throws Exception {
        mockMvc.perform(get("/users/1")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.email").value("admin@tecsys.com"))
                .andExpect(jsonPath("$.password").doesNotExist());
    }

    @Test
    void shouldReturnNotFoundWhenUserDoesNotExist() throws Exception {
        mockMvc.perform(get("/users/99999")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").isNotEmpty());
    }

    @Test
    void shouldRejectAccessWhenOperatorTriesToViewAnotherUser() throws Exception {
        LoginRequest operatorLogin = new LoginRequest("operador@distribuidora.com.br", "Oper@456");
        MvcResult result = mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(operatorLogin)))
                .andExpect(status().isOk())
                .andReturn();

        String operatorToken = objectMapper.readTree(result.getResponse().getContentAsString()).get("token").asText();

        mockMvc.perform(get("/users/1")
                        .header("Authorization", "Bearer " + operatorToken))
                .andExpect(status().isForbidden());

        mockMvc.perform(get("/users/2")
                        .header("Authorization", "Bearer " + operatorToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(2));
    }

    @Test
    void shouldUpdateUserAndChangePasswordSecurely() throws Exception {
        CreateUserRequest createReq = CreateUserRequest.builder()
                .nome("Usuario Para Update")
                .email("update.teste@tecsys.com")
                .senha("Senha@123")
                .confirmarSenha("Senha@123")
                .build();

        MvcResult createRes = mockMvc.perform(post("/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createReq)))
                .andExpect(status().isCreated())
                .andReturn();

        Long createdId = objectMapper.readTree(createRes.getResponse().getContentAsString()).get("id").asLong();

        LoginRequest loginReq = new LoginRequest("update.teste@tecsys.com", "Senha@123");
        MvcResult loginRes = mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginReq)))
                .andExpect(status().isOk())
                .andReturn();

        String userToken = objectMapper.readTree(loginRes.getResponse().getContentAsString()).get("token").asText();

        UpdateUserRequest updateReq = UpdateUserRequest.builder()
                .nome("Nome Atualizado")
                .senha("NovaSenha@456")
                .confirmarSenha("NovaSenha@456")
                .build();

        mockMvc.perform(put("/users/" + createdId)
                        .header("Authorization", "Bearer " + userToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nome").value("Nome Atualizado"))
                .andExpect(jsonPath("$.password").doesNotExist());

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new LoginRequest("update.teste@tecsys.com", "Senha@123"))))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new LoginRequest("update.teste@tecsys.com", "NovaSenha@456"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty());
    }

    @Test
    void shouldRejectPatchMethodOnUsers() throws Exception {
        mockMvc.perform(patch("/users/1")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nome\":\"Teste Patch\"}"))
                .andExpect(status().isMethodNotAllowed());
    }


    @Test
    void shouldDeleteUserAndRevokeSessions() throws Exception {
        CreateUserRequest createReq = CreateUserRequest.builder()
                .nome("Usuario Deletavel")
                .email("delete.me@tecsys.com")
                .senha("Senha@123")
                .confirmarSenha("Senha@123")
                .build();

        MvcResult createRes = mockMvc.perform(post("/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createReq)))
                .andExpect(status().isCreated())
                .andReturn();

        Long createdId = objectMapper.readTree(createRes.getResponse().getContentAsString()).get("id").asLong();

        LoginRequest loginReq = new LoginRequest("delete.me@tecsys.com", "Senha@123");
        MvcResult loginRes = mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginReq)))
                .andExpect(status().isOk())
                .andReturn();

        String refreshToken = objectMapper.readTree(loginRes.getResponse().getContentAsString()).get("refreshToken").asText();

        mockMvc.perform(delete("/users/" + createdId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/users/" + createdId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isNotFound());

        mockMvc.perform(post("/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"" + refreshToken + "\"}"))
                .andExpect(status().isUnauthorized());
    }
}
