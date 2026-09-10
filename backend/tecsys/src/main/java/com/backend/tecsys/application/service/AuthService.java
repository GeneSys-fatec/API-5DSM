package com.backend.tecsys.application.service;

import com.backend.tecsys.domain.model.User;
import com.backend.tecsys.domain.repository.IUserRepository;
import com.backend.tecsys.infrastructure.security.JwtService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * Serviço de autenticação. Depende apenas de {@link IUserRepository} (interface),
 * nunca da implementação concreta. Quando MySQL estiver disponível, nenhuma
 * linha deste serviço precisa mudar.
 */
@Service
public class AuthService {

    private final IUserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(IUserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    /**
     * Autentica um usuário com email e senha.
     *
     * @return JWT token se credenciais válidas
     * @throws AuthenticationException se credenciais inválidas
     */
    public AuthResult authenticate(String email, String password) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new AuthenticationException("E-mail ou senha inválidos."));

        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new AuthenticationException("E-mail ou senha inválidos.");
        }

        String token = jwtService.generateToken(user.getId(), user.getEmail());

        return new AuthResult(token, user);
    }

    /**
     * Busca um usuário pelo ID (usado pela rota /auth/me).
     */
    public User getUserById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new AuthenticationException("Usuário não encontrado."));
    }

    /**
     * Resultado de autenticação bem-sucedida.
     */
    public record AuthResult(String token, User user) {}

    /**
     * Exceção de autenticação com mensagem amigável.
     */
    public static class AuthenticationException extends RuntimeException {
        public AuthenticationException(String message) {
            super(message);
        }
    }
}
