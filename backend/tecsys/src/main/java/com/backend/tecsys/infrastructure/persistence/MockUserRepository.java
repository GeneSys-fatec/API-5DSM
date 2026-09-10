package com.backend.tecsys.infrastructure.persistence;

import com.backend.tecsys.domain.model.User;
import com.backend.tecsys.domain.repository.IUserRepository;
import jakarta.annotation.PostConstruct;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Implementação mock do repositório de usuários com dados em memória.
 *
 * <p>Ativa apenas com o profile "mock". Quando MySQL estiver disponível,
 * crie uma implementação JPA de {@link IUserRepository} com {@code @Profile("prod")}
 * e troque o profile ativo em application.properties.</p>
 */
@Repository
@Profile("mock")
public class MockUserRepository implements IUserRepository {

    private final List<User> users = new ArrayList<>();
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    @PostConstruct
    public void init() {
        users.add(User.builder()
                .id(1L)
                .name("Administrador Tecsys")
                .email("admin@tecsys.com")
                .password(encoder.encode("Admin@123"))
                .build());

        users.add(User.builder()
                .id(2L)
                .name("Operador de Campo")
                .email("operador@distribuidora.com.br")
                .password(encoder.encode("Oper@456"))
                .build());
    }

    @Override
    public Optional<User> findByEmail(String email) {
        return users.stream()
                .filter(u -> u.getEmail().equalsIgnoreCase(email))
                .findFirst();
    }

    @Override
    public Optional<User> findById(Long id) {
        return users.stream()
                .filter(u -> u.getId().equals(id))
                .findFirst();
    }
}
