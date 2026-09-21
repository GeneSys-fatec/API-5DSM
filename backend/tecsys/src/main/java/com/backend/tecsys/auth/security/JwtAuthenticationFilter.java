package com.backend.tecsys.auth.security;

import com.backend.tecsys.auth.model.User;
import com.backend.tecsys.auth.repository.IUserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final IUserRepository userRepository;

    public JwtAuthenticationFilter(JwtService jwtService, IUserRepository userRepository) {
        this.jwtService = jwtService;
        this.userRepository = userRepository;
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain) throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = authHeader.substring(7);

        JwtService.TokenValidationStatus status = jwtService.validateToken(token);

        if (status == JwtService.TokenValidationStatus.EXPIRED) {
            writeErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "Token expirado", "TOKEN_EXPIRED");
            return;
        }

        if (status == JwtService.TokenValidationStatus.INVALID) {
            writeErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "Token inválido", "TOKEN_INVALID");
            return;
        }

        String tokenType = jwtService.extractTokenType(token);
        if (tokenType != null && !"ACCESS".equalsIgnoreCase(tokenType)) {
            writeErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "Token inválido para autenticação", "TOKEN_INVALID");
            return;
        }

        Long userId;
        try {
            userId = jwtService.extractUserId(token);
        } catch (Exception e) {
            writeErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "Falha ao processar token", "TOKEN_INVALID");
            return;
        }

        Optional<User> userOpt = userRepository.findById(userId);

        if (userOpt.isEmpty()) {
            writeErrorResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "Usuário não encontrado", "USER_NOT_FOUND");
            return;
        }

        User user = userOpt.get();

        List<GrantedAuthority> authorities = new ArrayList<>();
        if (user.getRole() != null && !user.getRole().isBlank()) {
            authorities.add(new SimpleGrantedAuthority("ROLE_" + user.getRole()));
        }

        UsernamePasswordAuthenticationToken authentication =
                new UsernamePasswordAuthenticationToken(user, null, authorities);

        SecurityContextHolder.getContext().setAuthentication(authentication);

        filterChain.doFilter(request, response);
    }

    private void writeErrorResponse(
            HttpServletResponse response,
            int statusCode,
            String message,
            String code) throws IOException {
        response.setStatus(statusCode);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");

        String json = String.format(
                "{\"error\":\"%s\",\"code\":\"%s\",\"status\":%d,\"timestamp\":\"%s\"}",
                message, code, statusCode, LocalDateTime.now()
        );

        response.getWriter().write(json);
    }
}
