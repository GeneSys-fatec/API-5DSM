package com.backend.tecsys.auth.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PasswordResetToken {
    private Long id;
    private Long usuarioId;
    private String tokenHash;
    private Instant expiraEm;
    private boolean usado;
}
