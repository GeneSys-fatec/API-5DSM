package com.backend.tecsys;

import com.backend.tecsys.scenario.catalog.BdgdAssetCatalog;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

class BdgdAssetCatalogTest {

    private BdgdAssetCatalog catalog;

    @BeforeEach
    void setUp() {
        catalog = new BdgdAssetCatalog();
    }

    @Test
    @DisplayName("Deve resolver sinônimos de postes para a família POSTE")
    void shouldResolvePosteAliases() {
        assertEquals(BdgdAssetCatalog.AssetFamily.POSTE, catalog.resolveFamily("POSTE"));
        assertEquals(BdgdAssetCatalog.AssetFamily.POSTE, catalog.resolveFamily("PONNOT"));
        assertEquals(BdgdAssetCatalog.AssetFamily.POSTE, catalog.resolveFamily("post"));
        assertEquals(BdgdAssetCatalog.AssetFamily.POSTE, catalog.resolveFamily("TORRE"));
        assertEquals(BdgdAssetCatalog.AssetFamily.POSTE, catalog.resolveFamily("ESTRUTURA"));

        assertEquals("POSTE", catalog.canonicalCode("PONNOT"));
        assertEquals("POSTE", catalog.canonicalCode("POSTE"));
        assertTrue(catalog.isGatewayEligible("PONNOT"));
        assertTrue(catalog.isGatewayEligible("POSTE"));
    }

    @Test
    @DisplayName("Deve resolver transformadores e reguladores")
    void shouldResolveTransformersAndRegulators() {
        assertEquals(BdgdAssetCatalog.AssetFamily.TRAFO, catalog.resolveFamily("UNTRMT"));
        assertEquals(BdgdAssetCatalog.AssetFamily.TRAFO, catalog.resolveFamily("UNTRD"));
        assertEquals(BdgdAssetCatalog.AssetFamily.TRAFO, catalog.resolveFamily("TRAFO"));
        assertEquals(BdgdAssetCatalog.AssetFamily.TRAFO, catalog.resolveFamily("transformador"));
        assertEquals("TRAFO", catalog.canonicalCode("UNTRMT"));

        assertEquals(BdgdAssetCatalog.AssetFamily.RELIGADOR, catalog.resolveFamily("UNREMT"));
        assertEquals(BdgdAssetCatalog.AssetFamily.RELIGADOR, catalog.resolveFamily("UNCRMT"));
        assertEquals(BdgdAssetCatalog.AssetFamily.RELIGADOR, catalog.resolveFamily("UNCRAT"));
        assertEquals(BdgdAssetCatalog.AssetFamily.RELIGADOR, catalog.resolveFamily("RELIGADOR"));
        assertEquals(BdgdAssetCatalog.AssetFamily.RELIGADOR, catalog.resolveFamily("PARARRAIOS"));
        assertEquals("RELIGADOR", catalog.canonicalCode("UNREMT"));
    }

    @Test
    @DisplayName("Deve resolver subestações e redes")
    void shouldResolveSubAndNetworkSegments() {
        assertEquals(BdgdAssetCatalog.AssetFamily.SUB, catalog.resolveFamily("SUB"));
        assertEquals(BdgdAssetCatalog.AssetFamily.SUB, catalog.resolveFamily("SUBESTACAO"));
        assertEquals("SUB", catalog.canonicalCode("SUBESTACAO"));
        assertTrue(catalog.isGatewayEligible("SUB"));

        assertEquals(BdgdAssetCatalog.AssetFamily.SSDMT, catalog.resolveFamily("SSDMT"));
        assertEquals(BdgdAssetCatalog.AssetFamily.SSDBT, catalog.resolveFamily("SSDBT"));
        assertEquals(BdgdAssetCatalog.AssetFamily.SSDAT, catalog.resolveFamily("SSDAT"));
        assertFalse(catalog.isGatewayEligible("SSDMT"));
        assertFalse(catalog.isGatewayEligible("SSDBT"));
    }

    @Test
    @DisplayName("Deve expandir filtros bidirecionalmente com todos os aliases")
    void shouldExpandFiltersBidirectionally() {
        Set<String> expandedPoste = catalog.expandFilter(List.of("POSTE"));
        assertTrue(expandedPoste.contains("POSTE"));
        assertTrue(expandedPoste.contains("PONNOT"));
        assertTrue(expandedPoste.contains("POST"));
        assertTrue(expandedPoste.contains("TORRE"));

        Set<String> expandedPonnot = catalog.expandFilter(List.of("PONNOT"));
        assertEquals(expandedPoste, expandedPonnot);

        Set<String> expandedTrafo = catalog.expandFilter(List.of("TRAFO"));
        assertTrue(expandedTrafo.contains("UNTRMT"));
        assertTrue(expandedTrafo.contains("UNTRD"));
        assertTrue(expandedTrafo.contains("TRAFO"));
    }

    @Test
    @DisplayName("Deve tratar tipos desconhecidos com elegância no princípio de mundo aberto")
    void shouldHandleUnknownTypesGracefully() {
        assertEquals(BdgdAssetCatalog.AssetFamily.OUTROS, catalog.resolveFamily("SIGLA_INEDITA"));
        assertEquals("SIGLA_INEDITA", catalog.canonicalCode("sigla_inedita"));
        assertFalse(catalog.isGatewayEligible("SIGLA_INEDITA"));

        Set<String> expanded = catalog.expandFilter(List.of("SIGLA_INEDITA"));
        assertTrue(expanded.contains("SIGLA_INEDITA"));
    }
}
