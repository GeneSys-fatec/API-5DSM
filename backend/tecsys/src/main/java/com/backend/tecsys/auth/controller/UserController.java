package com.backend.tecsys.auth.controller;

import com.backend.tecsys.auth.dto.CreateUserRequest;
import com.backend.tecsys.auth.dto.UpdateUserRequest;
import com.backend.tecsys.auth.dto.UserResponse;
import com.backend.tecsys.auth.model.User;
import com.backend.tecsys.auth.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/users")
@Tag(name = "Usuários", description = "Endpoints de gerenciamento e CRUD de usuários")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(
            summary = "Cadastrar usuário",
            description = "Cria um novo usuário no sistema com senha criptografada via BCrypt. Endpoint público utilizado pela tela de cadastro."
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "201",
                    description = "Usuário cadastrado com sucesso",
                    content = @Content(schema = @Schema(implementation = UserResponse.class))
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Dados inválidos ou confirmação de senha não confere",
                    content = @Content(schema = @Schema(example = "{\"error\":\"A confirmação de senha não confere com a senha informada.\",\"status\":400}"))
            ),
            @ApiResponse(
                    responseCode = "409",
                    description = "E-mail já cadastrado",
                    content = @Content(schema = @Schema(example = "{\"error\":\"O e-mail informado já está cadastrado.\",\"status\":409}"))
            )
    })
    public ResponseEntity<UserResponse> createUser(@Valid @RequestBody CreateUserRequest request) {
        UserResponse created = userService.createUser(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @GetMapping
    @Operation(
            summary = "Listar usuários",
            description = "Retorna a listagem de todos os usuários cadastrados. Exige autenticação Bearer JWT.",
            security = @SecurityRequirement(name = "Bearer Authentication")
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Lista de usuários retornada com sucesso",
                    content = @Content(array = @ArraySchema(schema = @Schema(implementation = UserResponse.class)))
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Não autenticado ou token inválido/expirado"
            )
    })
    public ResponseEntity<List<UserResponse>> getAllUsers() {
        List<UserResponse> users = userService.getAllUsers();
        return ResponseEntity.ok(users);
    }

    @GetMapping("/{id}")
    @Operation(
            summary = "Consultar usuário por ID",
            description = "Busca os dados cadastrais de um usuário específico pelo ID. Exige autenticação Bearer JWT.",
            security = @SecurityRequirement(name = "Bearer Authentication")
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Usuário encontrado com sucesso",
                    content = @Content(schema = @Schema(implementation = UserResponse.class))
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Não autenticado ou token inválido"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Sem permissão para visualizar este usuário"
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Usuário não encontrado"
            )
    })
    public ResponseEntity<UserResponse> getUserById(
            @Parameter(description = "ID do usuário a consultar", example = "1")
            @PathVariable Long id,
            @Parameter(hidden = true)
            @AuthenticationPrincipal User currentUser) {
        UserResponse user = userService.getUserById(id, currentUser);
        return ResponseEntity.ok(user);
    }

    @PutMapping("/{id}")
    @Operation(
            summary = "Atualizar usuário",
            description = "Atualiza dados cadastrais do usuário (nome, e-mail, senha). Exige autenticação Bearer JWT.",
            security = @SecurityRequirement(name = "Bearer Authentication")
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "200",
                    description = "Usuário atualizado com sucesso",
                    content = @Content(schema = @Schema(implementation = UserResponse.class))
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Dados inválidos ou confirmação de senha incorreta"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Não autenticado ou token inválido"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Sem permissão para alterar este usuário"
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Usuário não encontrado"
            ),
            @ApiResponse(
                    responseCode = "409",
                    description = "Novo e-mail já pertence a outro usuário"
            )
    })
    public ResponseEntity<UserResponse> updateUser(
            @Parameter(description = "ID do usuário a atualizar", example = "1")
            @PathVariable Long id,
            @Valid @RequestBody UpdateUserRequest request,
            @Parameter(hidden = true)
            @AuthenticationPrincipal User currentUser) {
        UserResponse updated = userService.updateUser(id, request, currentUser);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(
            summary = "Remover usuário",
            description = "Remove o usuário e revoga imediatamente todas as suas sessões e refresh tokens. Exige autenticação Bearer JWT.",
            security = @SecurityRequirement(name = "Bearer Authentication")
    )
    @ApiResponses({
            @ApiResponse(
                    responseCode = "204",
                    description = "Usuário removido com sucesso e sessões revogadas"
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Não autenticado ou token inválido"
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Sem permissão para remover este usuário"
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Usuário não encontrado"
            )
    })
    public ResponseEntity<Void> deleteUser(
            @Parameter(description = "ID do usuário a remover", example = "1")
            @PathVariable Long id,
            @Parameter(hidden = true)
            @AuthenticationPrincipal User currentUser) {
        userService.deleteUser(id, currentUser);
        return ResponseEntity.noContent().build();
    }
}
