package com.backend.tecsys.auth.repository;

import com.backend.tecsys.auth.model.User;
import jakarta.annotation.PostConstruct;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicLong;

@Repository
@Profile("mock")
public class MockUserRepository implements IUserRepository {

    private final List<User> users = Collections.synchronizedList(new ArrayList<>());
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
    private final AtomicLong idSequence = new AtomicLong(10);

    @PostConstruct
    public void init() {
        users.clear();
        users.add(User.builder()
                .id(1L)
                .name("Administrador Tecsys")
                .email("admin@tecsys.com")
                .password(encoder.encode("Admin@123"))
                .role("ADMIN")
                .utilityId(1L)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build());

        users.add(User.builder()
                .id(2L)
                .name("Operador de Campo")
                .email("operador@distribuidora.com.br")
                .password(encoder.encode("Oper@456"))
                .role("OPERATOR")
                .utilityId(1L)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build());
    }

    @Override
    public Optional<User> findByEmail(String email) {
        if (email == null) return Optional.empty();
        synchronized (users) {
            return users.stream()
                    .filter(u -> u.getEmail().equalsIgnoreCase(email.trim()))
                    .findFirst();
        }
    }

    @Override
    public Optional<User> findById(Long id) {
        if (id == null) return Optional.empty();
        synchronized (users) {
            return users.stream()
                    .filter(u -> u.getId().equals(id))
                    .findFirst();
        }
    }

    @Override
    public List<User> findAll() {
        synchronized (users) {
            return new ArrayList<>(users);
        }
    }

    @Override
    public User save(User user) {
        if (user.getId() == null) {
            user.setId(idSequence.incrementAndGet());
        }
        if (user.getCreatedAt() == null) {
            user.setCreatedAt(LocalDateTime.now());
        }
        user.setUpdatedAt(LocalDateTime.now());
        users.add(user);
        return user;
    }

    @Override
    public User update(User updatedUser) {
        synchronized (users) {
            for (int i = 0; i < users.size(); i++) {
                if (users.get(i).getId().equals(updatedUser.getId())) {
                    updatedUser.setUpdatedAt(LocalDateTime.now());
                    if (updatedUser.getCreatedAt() == null) {
                        updatedUser.setCreatedAt(users.get(i).getCreatedAt());
                    }
                    users.set(i, updatedUser);
                    return updatedUser;
                }
            }
        }
        return save(updatedUser);
    }

    @Override
    public void deleteById(Long id) {
        if (id == null) return;
        synchronized (users) {
            users.removeIf(u -> u.getId().equals(id));
        }
    }

    @Override
    public boolean existsByEmail(String email) {
        return findByEmail(email).isPresent();
    }
}

