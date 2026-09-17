package com.backend.tecsys.domain.repository;

import com.backend.tecsys.domain.model.User;
import java.util.Optional;

public interface IUserRepository {

    Optional<User> findByEmail(String email);

    Optional<User> findById(Long id);
}
