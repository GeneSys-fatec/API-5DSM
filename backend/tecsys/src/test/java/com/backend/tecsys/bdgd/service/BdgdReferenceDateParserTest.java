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
    void rejectsFileWithoutReferenceDateInsteadOfUsingUploadDate() {
        assertThrows(IllegalArgumentException.class,
                () -> BdgdReferenceDateParser.parseRequired("Chesp_upload.gdb.zip"));
    }
}