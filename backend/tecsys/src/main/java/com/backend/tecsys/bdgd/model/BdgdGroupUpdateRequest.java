package com.backend.tecsys.bdgd.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record BdgdGroupUpdateRequest(
        @NotBlank(message = "A regiao e obrigatoria")
        @Size(max = 120, message = "A regiao deve ter no maximo 120 caracteres")
        String regiao,
        @NotBlank(message = "A distribuidora e obrigatoria")
        @Size(max = 120, message = "A distribuidora deve ter no maximo 120 caracteres")
        String distribuidora) {
}
