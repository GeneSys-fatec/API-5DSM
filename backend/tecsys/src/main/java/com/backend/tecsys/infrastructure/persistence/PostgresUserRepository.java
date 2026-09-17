package com.backend.tecsys.infrastructure.persistence;

import com.backend.tecsys.domain.model.User;
import com.backend.tecsys.domain.repository.IUserRepository;
import org.springframework.context.annotation.Profile;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
@Profile("!mock")
public class PostgresUserRepository implements IUserRepository {

    private final JdbcTemplate jdbcTemplate;

    private final RowMapper<User> userRowMapper = (rs, rowNum) -> User.builder()
            .id(rs.getLong("id"))
            .name(rs.getString("nome"))
            .email(rs.getString("email"))
            .password(rs.getString("senha_hash"))
            .role(rs.getString("papel") != null ? rs.getString("papel").toUpperCase() : "ENGENHEIRO")
            .build();

    public PostgresUserRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public Optional<User> findByEmail(String email) {
        try {
            String sql = "SELECT id, nome, email, senha_hash, papel FROM app.usuario WHERE LOWER(email) = LOWER(?)";
            User user = jdbcTemplate.queryForObject(sql, userRowMapper, email);
            return Optional.ofNullable(user);
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    @Override
    public Optional<User> findById(Long id) {
        try {
            String sql = "SELECT id, nome, email, senha_hash, papel FROM app.usuario WHERE id = ?";
            User user = jdbcTemplate.queryForObject(sql, userRowMapper, id);
            return Optional.ofNullable(user);
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }
}
