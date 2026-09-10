package com.backend.tecsys.presentation.dto;

import lombok.Data;

@Data
public class LoginRequest {
    private String email;
    private String password;
}
