package com.backend.tecsys;

import com.backend.tecsys.bdgd.exception.InvalidBdgdUploadException;
import com.backend.tecsys.bdgd.service.BdgdGroupValidator;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

class BdgdGroupValidatorTest {

    private final BdgdGroupValidator validator = new BdgdGroupValidator();

    @Test
    void shouldTrimSurroundingAndRepeatedWhitespace() {
        assertEquals("Regiao Sul", validator.normalizeAndValidate("  Regiao   Sul  ", "Regiao"));
        assertEquals("CEMIG", validator.normalizeAndValidate("\tCEMIG\n", "Distribuidora"));
    }

    @Test
    void shouldAcceptValueExactlyAtColumnLimit() {
        String value = "R".repeat(BdgdGroupValidator.MAX_LENGTH);
        assertEquals(value, validator.normalizeAndValidate(value, "Regiao"));
    }

    @Test
    void shouldRejectValueLongerThanColumnLimit() {
        String value = "R".repeat(BdgdGroupValidator.MAX_LENGTH + 1);
        InvalidBdgdUploadException exception =
                assertThrows(InvalidBdgdUploadException.class, () -> validator.normalizeAndValidate(value, "Regiao"));
        assertEquals("Regiao deve ter no maximo 120 caracteres", exception.getMessage());
    }

    @Test
    void shouldRejectNullAndBlankValues() {
        assertThrows(InvalidBdgdUploadException.class, () -> validator.normalizeAndValidate(null, "Regiao"));
        assertThrows(InvalidBdgdUploadException.class, () -> validator.normalizeAndValidate("", "Distribuidora"));
        assertThrows(InvalidBdgdUploadException.class, () -> validator.normalizeAndValidate("   \t ", "Distribuidora"));
    }

    @Test
    void shouldRejectControlCharacters() {
        assertThrows(InvalidBdgdUploadException.class,
                () -> validator.normalizeAndValidate("CEMIG\u0000", "Distribuidora"));
        assertThrows(InvalidBdgdUploadException.class,
                () -> validator.normalizeAndValidate("Regiao\u0007", "Regiao"));
    }

    @Test
    void shouldAcceptAccentedNames() {
        assertEquals("Sao Jose do Rio Preto", validator.normalizeAndValidate("Sao  Jose  do Rio Preto", "Regiao"));
        assertDoesNotThrow(() -> validator.normalizeAndValidate("São José dos Campos", "Regiao"));
    }

    @Test
    void normalizeShouldMapBlankToNullWithoutThrowing() {
        assertNull(validator.normalize(null));
        assertNull(validator.normalize("  "));
        assertEquals("Alfa Energia", validator.normalize("  Alfa Energia "));
    }

    @Test
    void shouldValidateAndNormalizeAllowedRegions() {
        for (String region : BdgdGroupValidator.ALLOWED_REGIONS) {
            assertEquals(region, validator.validateAndNormalizeRegion(region.toLowerCase()));
            assertEquals(region, validator.validateAndNormalizeRegion("  " + region.toUpperCase() + "  "));
        }
        assertEquals("Centro-Oeste", validator.validateAndNormalizeRegion("Centro Oeste"));
        assertEquals("Centro-Oeste", validator.validateAndNormalizeRegion("centro-oeste"));
    }

    @Test
    void shouldRejectInvalidRegion() {
        InvalidBdgdUploadException ex = assertThrows(
                InvalidBdgdUploadException.class,
                () -> validator.validateAndNormalizeRegion("Regiao Inexistente")
        );
        assertEquals(true, ex.getMessage().contains("Regiao invalida"));
        assertEquals(true, ex.getMessage().contains("Centro-Oeste"));
    }

    @Test
    void shouldValidateAndNormalizeAneelDistributors() {
        assertDoesNotThrow(() -> validator.validateAndNormalizeDistributor("CPFL-PAULISTA"));
        assertDoesNotThrow(() -> validator.validateAndNormalizeDistributor("cpfl-paulista"));
        assertDoesNotThrow(() -> validator.validateAndNormalizeDistributor("CEMIG-D"));
        assertDoesNotThrow(() -> validator.validateAndNormalizeDistributor("cemig-d"));
        assertDoesNotThrow(() -> validator.validateAndNormalizeDistributor("EDP SP"));
        assertDoesNotThrow(() -> validator.validateAndNormalizeDistributor("ENEL RJ"));
        assertDoesNotThrow(() -> validator.validateAndNormalizeDistributor("CELESC"));
        assertDoesNotThrow(() -> validator.validateAndNormalizeDistributor("CEMIG"));
    }

    @Test
    void shouldRejectInvalidDistributor() {
        InvalidBdgdUploadException ex = assertThrows(
                InvalidBdgdUploadException.class,
                () -> validator.validateAndNormalizeDistributor("Empresa Fake")
        );
        assertEquals(true, ex.getMessage().contains("Distribuidora invalida"));
    }
}
