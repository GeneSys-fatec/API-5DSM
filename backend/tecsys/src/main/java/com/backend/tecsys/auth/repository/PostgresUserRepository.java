package com.backend.tecsys.auth.repository;

import com.backend.tecsys.auth.model.User;
import org.springframework.context.annotation.Profile;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
@Profile("!mock")
public class PostgresUserRepository implements IUserRepository {

    private final JdbcTemplate jdbcTemplate;

    private final RowMapper<User> userRowMapper = (rs, rowNum) -> {
        Timestamp criadoEm = null;
        try {
            criadoEm = rs.getTimestamp("criado_em");
        } catch (Exception ignored) {}

        return User.builder()
                .id(rs.getLong("id"))
                .name(rs.getString("nome"))
                .email(rs.getString("email"))
                .password(rs.getString("senha_hash"))
                .role(rs.getString("papel") != null ? rs.getString("papel").toUpperCase() : "ENGENHEIRO")
                .utilityId(rs.getObject("distribuidora_id") != null ? rs.getLong("distribuidora_id") : null)
                .createdAt(criadoEm != null ? criadoEm.toLocalDateTime() : null)
                .updatedAt(criadoEm != null ? criadoEm.toLocalDateTime() : null)
                .build();
    };

    public PostgresUserRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public Optional<User> findByEmail(String email) {
        if (email == null) return Optional.empty();
        try {
            String sql = "SELECT id, nome, email, senha_hash, papel, distribuidora_id, criado_em FROM app.usuario WHERE LOWER(email) = LOWER(?)";
            User user = jdbcTemplate.queryForObject(sql, userRowMapper, email.trim());
            return Optional.ofNullable(user);
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    @Override
    public Optional<User> findById(Long id) {
        if (id == null) return Optional.empty();
        try {
            String sql = "SELECT id, nome, email, senha_hash, papel, distribuidora_id, criado_em FROM app.usuario WHERE id = ?";
            User user = jdbcTemplate.queryForObject(sql, userRowMapper, id);
            return Optional.ofNullable(user);
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    @Override
    public List<User> findAll() {
        String sql = "SELECT id, nome, email, senha_hash, papel, distribuidora_id, criado_em FROM app.usuario ORDER BY id ASC";
        return jdbcTemplate.query(sql, userRowMapper);
    }

    @Override
    public User save(User user) {
        String papel = user.getRole() != null ? user.getRole().toLowerCase() : "engenheiro";
        Long requestedUtilityId = user.getUtilityId() != null ? user.getUtilityId() : 1L;

        String sql = "INSERT INTO app.usuario (nome, email, senha_hash, papel, distribuidora_id, criado_em) " +
                "VALUES (?, ?, ?, ?, COALESCE((SELECT id FROM app.distribuidora WHERE id = ?), (SELECT id FROM app.distribuidora LIMIT 1)), now()) " +
                "RETURNING id, criado_em";

        return jdbcTemplate.queryForObject(sql, (rs, rowNum) -> {
            user.setId(rs.getLong("id"));
            Timestamp criado = rs.getTimestamp("criado_em");
            user.setCreatedAt(criado != null ? criado.toLocalDateTime() : LocalDateTime.now());
            user.setUpdatedAt(criado != null ? criado.toLocalDateTime() : LocalDateTime.now());
            return user;
        }, user.getName(), user.getEmail(), user.getPassword(), papel, requestedUtilityId);
    }

    @Override
    public User update(User user) {
        String papel = user.getRole() != null ? user.getRole().toLowerCase() : "engenheiro";
        String sql = "UPDATE app.usuario SET nome = ?, email = ?, senha_hash = ?, papel = ? WHERE id = ?";
        jdbcTemplate.update(sql, user.getName(), user.getEmail(), user.getPassword(), papel, user.getId());
        user.setUpdatedAt(LocalDateTime.now());
        return user;
    }

    @Override
    public void deleteById(Long id) {
        if (id == null) return;
        String sql = "DELETE FROM app.usuario WHERE id = ?";
        jdbcTemplate.update(sql, id);
    }

    @Override
    public boolean existsByEmail(String email) {
        if (email == null) return false;
        String sql = "SELECT count(1) FROM app.usuario WHERE LOWER(email) = LOWER(?)";
        Integer count = jdbcTemplate.queryForObject(sql, Integer.class, email.trim());
        return count != null && count > 0;
    }
}

