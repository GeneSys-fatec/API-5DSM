package com.backend.tecsys.bdgd.service;

import com.backend.tecsys.bdgd.exception.InvalidBdgdUploadException;

import org.springframework.stereotype.Component;

@Component
public class BdgdGroupValidator {
    public static final int MAX_LENGTH = 120;

    public String normalizeAndValidate(String value, String fieldLabel) {
        String normalized = normalize(value);
        if (normalized == null) {
            throw new InvalidBdgdUploadException(fieldLabel + " e obrigatorio");
        }
        if (normalized.length() > MAX_LENGTH) {
            throw new InvalidBdgdUploadException(
                    fieldLabel + " deve ter no maximo " + MAX_LENGTH + " caracteres");
        }
        if (containsControlCharacter(normalized)) {
            throw new InvalidBdgdUploadException(fieldLabel + " contem caracteres invalidos");
        }
        return normalized;
    }

    public String normalize(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.strip().replaceAll("\\s+", " ");
    }

    private boolean containsControlCharacter(String value) {
        return value.chars().anyMatch(Character::isISOControl);
    }
}
