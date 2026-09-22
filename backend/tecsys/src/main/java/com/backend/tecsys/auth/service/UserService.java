package com.backend.tecsys.auth.service;

import com.backend.tecsys.auth.dto.CreateUserRequest;
import com.backend.tecsys.auth.dto.UpdateUserRequest;
import com.backend.tecsys.auth.dto.UserResponse;
import com.backend.tecsys.auth.exception.EmailAlreadyExistsException;
import com.backend.tecsys.auth.exception.ForbiddenOperationException;
import com.backend.tecsys.auth.exception.PasswordMismatchException;
import com.backend.tecsys.auth.exception.UserNotFoundException;
import com.backend.tecsys.auth.model.User;
import com.backend.tecsys.auth.repository.IUserRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@Slf4j
public class UserService {

    private final IUserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final RefreshTokenService refreshTokenService;

    public UserService(
            IUserRepository userRepository,
            PasswordEncoder passwordEncoder,
            RefreshTokenService refreshTokenService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.refreshTokenService = refreshTokenService;
    }

    public UserResponse createUser(CreateUserRequest request) {
        if (!request.getSenha().equals(request.getConfirmarSenha())) {
            throw new PasswordMismatchException("A confirmação de senha não confere com a senha informada.");
        }

        String normalizedEmail = request.getEmail().trim().toLowerCase();
        if (userRepository.existsByEmail(normalizedEmail)) {
            throw new EmailAlreadyExistsException("O e-mail informado já está cadastrado.");
        }

        String passwordHash = passwordEncoder.encode(request.getSenha());

        User newUser = User.builder()
                .name(request.getNome().trim())
                .email(normalizedEmail)
                .password(passwordHash)
                .role("ENGENHEIRO")
                .utilityId(1L)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        User savedUser = userRepository.save(newUser);
        log.info("Novo usuário cadastrado com sucesso. ID: {}", savedUser.getId());
        return UserResponse.fromUser(savedUser);
    }

    public UserResponse getUserById(Long id, User currentUser) {
        validateAccess(id, currentUser, "visualizar");

        User user = userRepository.findById(id)
                .orElseThrow(() -> new UserNotFoundException("Usuário com ID " + id + " não encontrado."));

        return UserResponse.fromUser(user);
    }

    public List<UserResponse> getAllUsers(User currentUser) {
        validateAdmin(currentUser);
        return userRepository.findAll().stream()
                .map(UserResponse::fromUser)
                .toList();
    }

    public UserResponse updateUser(Long id, UpdateUserRequest request, User currentUser) {
        validateAccess(id, currentUser, "alterar");

        User user = userRepository.findById(id)
                .orElseThrow(() -> new UserNotFoundException("Usuário com ID " + id + " não encontrado."));

        if (request.getNome() != null && !request.getNome().isBlank()) {
            user.setName(request.getNome().trim());
        }

        if (request.getEmail() != null && !request.getEmail().isBlank()) {
            String newEmail = request.getEmail().trim().toLowerCase();
            if (!newEmail.equalsIgnoreCase(user.getEmail())) {
                if (userRepository.existsByEmail(newEmail)) {
                    throw new EmailAlreadyExistsException("O e-mail informado já está em uso por outro usuário.");
                }
                user.setEmail(newEmail);
            }
        }

        if (request.getSenha() != null && !request.getSenha().isBlank()) {
            if (request.getConfirmarSenha() == null || !request.getSenha().equals(request.getConfirmarSenha())) {
                throw new PasswordMismatchException("A confirmação da nova senha não confere com a senha informada.");
            }
            user.setPassword(passwordEncoder.encode(request.getSenha()));
            refreshTokenService.revokeAllForUser(id);
        }

        user.setUpdatedAt(LocalDateTime.now());
        User updated = userRepository.update(user);
        log.info("Usuário ID {} atualizado com sucesso.", id);
        return UserResponse.fromUser(updated);
    }

    public void deleteUser(Long id, User currentUser) {
        validateAccess(id, currentUser, "remover");

        if (userRepository.findById(id).isEmpty()) {
            throw new UserNotFoundException("Usuário com ID " + id + " não encontrado.");
        }

        refreshTokenService.revokeAllForUser(id);
        userRepository.deleteById(id);
        log.info("Usuário ID {} e suas sessões foram removidos com sucesso.", id);
    }

    private void validateAccess(Long targetUserId, User currentUser, String action) {
        if (currentUser == null) {
            throw new ForbiddenOperationException("Usuário não autenticado.");
        }

        boolean isAdmin = "ADMIN".equalsIgnoreCase(currentUser.getRole());
        boolean isSelf = currentUser.getId() != null && currentUser.getId().equals(targetUserId);

        if (!isAdmin && !isSelf) {
            throw new ForbiddenOperationException("Você não tem permissão para " + action + " os dados de outro usuário.");
        }
    }

    private void validateAdmin(User currentUser) {
        if (currentUser == null) {
            throw new ForbiddenOperationException("Usuário não autenticado.");
        }
        if (!"ADMIN".equalsIgnoreCase(currentUser.getRole())) {
            throw new ForbiddenOperationException("Você não tem permissão para listar todos os usuários.");
        }
    }
}
