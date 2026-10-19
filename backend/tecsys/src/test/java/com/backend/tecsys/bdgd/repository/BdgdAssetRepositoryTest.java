package com.backend.tecsys.bdgd.repository;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class BdgdAssetRepositoryTest {
    @Test
    void countsAssetsByImportIdInsteadOfReturningOneSharedCount() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        when(jdbc.queryForList(anyString(), eq(String.class))).thenReturn(List.of("poste"));

        UUID firstImport = UUID.randomUUID();
        UUID secondImport = UUID.randomUUID();
        when(jdbc.queryForObject(anyString(), eq(Integer.class), eq(firstImport.toString())))
                .thenReturn(45_909);
        when(jdbc.queryForObject(anyString(), eq(Integer.class), eq(secondImport.toString())))
                .thenReturn(5_258);

        BdgdAssetRepository repository = new BdgdAssetRepository(jdbc);

        int firstCount = repository.countAssetsByImportId(firstImport, List.of("poste"));
        int secondCount = repository.countAssetsByImportId(secondImport, List.of("poste"));

        assertEquals(45_909, firstCount);
        assertEquals(5_258, secondCount);
        assertNotEquals(firstCount, secondCount);
    }
}