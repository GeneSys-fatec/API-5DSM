package com.backend.tecsys.domain.model;

import com.backend.tecsys.domain.exception.UnsupportedPropagationModelException;

public enum PropagationModelType {
    OKUMURA_HATA_SUBURBAN,
    THREE_GPP_RURAL_MACRO,
    ITM_LONGLEY_RICE;

    public static PropagationModelType fromValue(String value) {
        if (value == null || value.isBlank()) {
            throw new UnsupportedPropagationModelException("O modelo de propagação é obrigatório.");
        }

        for (PropagationModelType type : values()) {
            if (type.name().equalsIgnoreCase(value.trim())) {
                return type;
            }
        }

        throw new UnsupportedPropagationModelException(
                "Modelo de propagação não suportado: " + value + ".");
    }
}
