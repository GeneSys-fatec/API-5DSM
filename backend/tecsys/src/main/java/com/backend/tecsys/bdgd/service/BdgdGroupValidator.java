package com.backend.tecsys.bdgd.service;

import com.backend.tecsys.bdgd.exception.InvalidBdgdUploadException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.text.Normalizer;
import java.util.List;

@Component
public class BdgdGroupValidator {
    public static final int MAX_LENGTH = 120;

    /** As 5 grandes regiões do Brasil são fixas e imutáveis. */
    public static final List<String> ALLOWED_REGIONS = List.of(
            "Centro-Oeste",
            "Nordeste",
            "Norte",
            "Sudeste",
            "Sul"
    );

    private final BdgdExternalDataService externalDataService;

    public BdgdGroupValidator() {
        this.externalDataService = new BdgdExternalDataService();
        this.externalDataService.loadFallbackData();
    }

    @Autowired
    public BdgdGroupValidator(BdgdExternalDataService externalDataService) {
        this.externalDataService = externalDataService != null
                ? externalDataService
                : new BdgdExternalDataService();
    }

    public List<String> getAllowedRegions() {
        return ALLOWED_REGIONS;
    }

    public List<String> getAllowedDistributors() {
        return externalDataService.getDistributors();
    }

    public String validateAndNormalizeRegion(String value) {
        String normalized = normalizeAndValidate(value, "Regiao");
        for (String allowed : ALLOWED_REGIONS) {
            if (isEquivalent(normalized, allowed)) {
                return allowed;
            }
        }
        throw new InvalidBdgdUploadException(
                "Regiao invalida: '" + normalized + "'. Valores permitidos: " + String.join(", ", ALLOWED_REGIONS));
    }

    public String validateAndNormalizeDistributor(String value) {
        String normalized = normalizeAndValidate(value, "Distribuidora");
        List<String> allowedList = getAllowedDistributors();
        for (String allowed : allowedList) {
            if (isEquivalent(normalized, allowed)) {
                return allowed;
            }
        }
        throw new InvalidBdgdUploadException(
                "Distribuidora invalida: '" + normalized + "'. Selecione uma distribuidora oficial da ANEEL.");
    }

    public boolean isEquivalent(String a, String b) {
        if (a == null || b == null) return false;
        if (a.equalsIgnoreCase(b)) return true;
        String ca = canonicalize(a);
        String cb = canonicalize(b);
        if (ca.equalsIgnoreCase(cb)) return true;
        if (ca.equalsIgnoreCase(cb + "D") || cb.equalsIgnoreCase(ca + "D")) return true;
        if (ca.equalsIgnoreCase(cb + "DIS") || cb.equalsIgnoreCase(ca + "DIS")) return true;
        return false;
    }

    private String canonicalize(String value) {
        String decomposed = Normalizer.normalize(value, Normalizer.Form.NFD);
        String withoutAccents = decomposed.replaceAll("\\p{M}", "");
        return withoutAccents.replaceAll("[^a-zA-Z0-9]", "");
    }

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
