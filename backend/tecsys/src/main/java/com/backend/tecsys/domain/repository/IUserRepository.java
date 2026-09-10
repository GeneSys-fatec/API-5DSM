package com.backend.tecsys.domain.repository;

import com.backend.tecsys.domain.model.User;
import java.util.Optional;

/**
 * Contrato para acesso a dados de usuário.
 *
 * <p>Quando o banco de dados real (MySQL) estiver pronto, basta criar uma implementação
 * JPA desta interface (ex: {@code JpaUserRepository}) e remover o profile "mock".
 * Nenhum service, controller ou filter precisa mudar.</p>
 */
public interface IUserRepository {

    Optional<User> findByEmail(String email);

    Optional<User> findById(Long id);
}
