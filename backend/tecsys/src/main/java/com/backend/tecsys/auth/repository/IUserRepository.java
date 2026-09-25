package com.backend.tecsys.auth.repository;

import com.backend.tecsys.auth.model.User;
import java.util.List;
import java.util.Optional;

public interface IUserRepository {

    Optional<User> findByEmail(String email);

    Optional<User> findById(Long id);

    List<User> findAll();

    User save(User user);

    User update(User user);

    void deleteById(Long id);

    boolean existsByEmail(String email);
}
