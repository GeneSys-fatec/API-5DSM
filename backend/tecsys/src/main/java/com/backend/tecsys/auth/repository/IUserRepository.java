package com.backend.tecsys.auth.repository;

import com.backend.tecsys.auth.model.User;
import java.util.Optional;

public interface IUserRepository {

    Optional<User> findByEmail(String email);

    Optional<User> findById(Long id);
}
