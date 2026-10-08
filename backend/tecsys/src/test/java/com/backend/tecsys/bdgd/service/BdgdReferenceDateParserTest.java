package com.backend.tecsys.bdgd.service;

import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class BdgdReferenceDateParserTest {
    @Test
    void extractsReferenceDateFromBdgdFileName() {
        assertEquals(
                LocalDate.of(2025, 12, 31),
                BdgdReferenceDateParser.parseRequired(
                        "Chesp_103_2025-12-31_V11_20260826-0016.gdb.zip"));
    }

    @Test
    void usesFormDateWhenFileNameHasNoReferenceDate() {
        assertEquals(
                LocalDate.of(2026, 8, 26),
                BdgdReferenceDateParser.parseOrDefault(
                        "Chesp_upload.gdb.zip", LocalDate.of(2026, 8, 26)));
    }

    @Test
    void stillRejectsMissingReferenceDateWhenRequiredParserIsUsed() {
        assertThrows(IllegalArgumentException.class,
                () -> BdgdReferenceDateParser.parseRequired("Chesp_upload.gdb.zip"));
    }
}