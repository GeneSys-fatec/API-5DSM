package com.backend.tecsys.bdgd.parser;

import com.backend.tecsys.bdgd.exception.InvalidBdgdUploadException;
import com.backend.tecsys.bdgd.model.AssetFileRecord;
import com.backend.tecsys.bdgd.service.AssetTemplateService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

public class AssetParsersTest {

    private CsvAssetParser csvParser;
    private JsonAssetParser jsonParser;
    private ExcelAssetParser excelParser;
    private AssetTemplateService templateService;

    @BeforeEach
    void setUp() {
        csvParser = new CsvAssetParser();
        jsonParser = new JsonAssetParser(new ObjectMapper());
        excelParser = new ExcelAssetParser();
        templateService = new AssetTemplateService();
    }

    @Test
    void shouldParseValidCsvWithCommaDelimiter() {
        String csv = """
                identificador,tipo_ativo,latitude,longitude
                POS-100,POSTE,-23.550520,-46.633308
                TR-200,TRAFO,-23.551200,-46.634100
                """;
        List<AssetFileRecord> records = csvParser.parse(
                new ByteArrayInputStream(csv.getBytes(StandardCharsets.UTF_8)),
                "CPFL",
                "SUDESTE"
        );

        assertEquals(2, records.size());
        assertEquals("POS-100", records.get(0).assetKey());
        assertEquals("POSTE", records.get(0).assetType());
        assertEquals(-23.550520, records.get(0).latitude(), 0.00001);
        assertEquals(-46.633308, records.get(0).longitude(), 0.00001);
        assertEquals("CPFL", records.get(0).distribuidora());
        assertEquals("SUDESTE", records.get(0).regiao());
    }

    @Test
    void shouldParseValidCsvWithSemicolonAndAlternateHeaders() {
        String csv = """
                id;categoria;lat;long;distribuidora;regiao
                REL-300;RELIGADOR;-22.906800;-47.061600;ENEL;LESTE
                """;
        List<AssetFileRecord> records = csvParser.parse(
                new ByteArrayInputStream(csv.getBytes(StandardCharsets.UTF_8)),
                "DEFAULT",
                "DEFAULT"
        );

        assertEquals(1, records.size());
        assertEquals("REL-300", records.get(0).assetKey());
        assertEquals("RELIGADOR", records.get(0).assetType());
        assertEquals("ENEL", records.get(0).distribuidora());
        assertEquals("LESTE", records.get(0).regiao());
    }

    @Test
    void shouldFailCsvMissingRequiredHeader() {
        String csv = """
                identificador,tipo_ativo,longitude
                POS-100,POSTE,-46.633308
                """;
        InvalidBdgdUploadException ex = assertThrows(InvalidBdgdUploadException.class, () ->
                csvParser.parse(new ByteArrayInputStream(csv.getBytes(StandardCharsets.UTF_8)), "CPFL", "SUDESTE")
        );

        assertTrue(ex.getMessage().contains("latitude"));
    }

    @Test
    void shouldFailCsvWithInvalidLatitudeRow() {
        String csv = """
                identificador,tipo_ativo,latitude,longitude
                POS-100,POSTE,-23.550520,-46.633308
                POS-101,POSTE,invalid_lat,-46.633308
                """;
        InvalidBdgdUploadException ex = assertThrows(InvalidBdgdUploadException.class, () ->
                csvParser.parse(new ByteArrayInputStream(csv.getBytes(StandardCharsets.UTF_8)), "CPFL", "SUDESTE")
        );

        assertTrue(ex.getMessage().contains("linha 3"));
        assertTrue(ex.getMessage().contains("latitude"));
    }

    @Test
    void shouldFailCsvWithEmptyIdentifier() {
        String csv = """
                identificador,tipo_ativo,latitude,longitude
                ,POSTE,-23.550520,-46.633308
                """;
        InvalidBdgdUploadException ex = assertThrows(InvalidBdgdUploadException.class, () ->
                csvParser.parse(new ByteArrayInputStream(csv.getBytes(StandardCharsets.UTF_8)), "CPFL", "SUDESTE")
        );

        assertTrue(ex.getMessage().contains("linha 2"));
        assertTrue(ex.getMessage().contains("identificador"));
    }

    @Test
    void shouldParseValidJsonArray() {
        String json = """
                [
                  {
                    "identificador": "POS-501",
                    "tipo_ativo": "POSTE",
                    "latitude": -23.550520,
                    "longitude": -46.633308
                  }
                ]
                """;
        List<AssetFileRecord> records = jsonParser.parse(
                new ByteArrayInputStream(json.getBytes(StandardCharsets.UTF_8)),
                "CPFL",
                "SUDESTE"
        );

        assertEquals(1, records.size());
        assertEquals("POS-501", records.get(0).assetKey());
        assertEquals("POSTE", records.get(0).assetType());
    }

    @Test
    void shouldParseValidJsonObjectWithAtivosKey() {
        String json = """
                {
                  "ativos": [
                    {
                      "codigo": "SUB-999",
                      "tipo": "SUBESTACAO",
                      "lat": -22.900,
                      "lon": -47.050
                    }
                  ]
                }
                """;
        List<AssetFileRecord> records = jsonParser.parse(
                new ByteArrayInputStream(json.getBytes(StandardCharsets.UTF_8)),
                "CPFL",
                "SUDESTE"
        );

        assertEquals(1, records.size());
        assertEquals("SUB-999", records.get(0).assetKey());
        assertEquals("SUBESTACAO", records.get(0).assetType());
    }

    @Test
    void shouldParseValidGeoJson() {
        String geojson = """
                {
                  "type": "FeatureCollection",
                  "features": [
                    {
                      "type": "Feature",
                      "geometry": {
                        "type": "Point",
                        "coordinates": [-46.633308, -23.550520]
                      },
                      "properties": {
                        "identificador": "GEO-01",
                        "tipo_ativo": "POSTE"
                      }
                    }
                  ]
                }
                """;
        List<AssetFileRecord> records = jsonParser.parse(
                new ByteArrayInputStream(geojson.getBytes(StandardCharsets.UTF_8)),
                "CPFL",
                "SUDESTE"
        );

        assertEquals(1, records.size());
        assertEquals("GEO-01", records.get(0).assetKey());
        assertEquals(-23.550520, records.get(0).latitude(), 0.00001);
        assertEquals(-46.633308, records.get(0).longitude(), 0.00001);
    }

    @Test
    void shouldFailJsonWithMissingField() {
        String json = """
                [
                  {
                    "tipo_ativo": "POSTE",
                    "latitude": -23.550520,
                    "longitude": -46.633308
                  }
                ]
                """;
        InvalidBdgdUploadException ex = assertThrows(InvalidBdgdUploadException.class, () ->
                jsonParser.parse(new ByteArrayInputStream(json.getBytes(StandardCharsets.UTF_8)), "CPFL", "SUDESTE")
        );

        assertTrue(ex.getMessage().contains("identificador"));
    }

    @Test
    void shouldParseValidExcelFile() throws Exception {
        byte[] excelBytes;
        try (Workbook wb = new XSSFWorkbook(); ByteArrayOutputStream bos = new ByteArrayOutputStream()) {
            Sheet sheet = wb.createSheet("Ativos");
            Row header = sheet.createRow(0);
            header.createCell(0).setCellValue("identificador");
            header.createCell(1).setCellValue("tipo_ativo");
            header.createCell(2).setCellValue("latitude");
            header.createCell(3).setCellValue("longitude");

            Row row = sheet.createRow(1);
            row.createCell(0).setCellValue("XLS-001");
            row.createCell(1).setCellValue("TRAFO");
            row.createCell(2).setCellValue(-23.551);
            row.createCell(3).setCellValue(-46.634);

            wb.write(bos);
            excelBytes = bos.toByteArray();
        }

        List<AssetFileRecord> records = excelParser.parse(new ByteArrayInputStream(excelBytes), "CPFL", "SUDESTE");
        assertEquals(1, records.size());
        assertEquals("XLS-001", records.get(0).assetKey());
        assertEquals("TRAFO", records.get(0).assetType());
    }

    @Test
    void shouldGenerateTemplatesProperly() {
        byte[] csv = templateService.getTemplate("csv");
        assertNotNull(csv);
        assertTrue(csv.length > 0);

        byte[] json = templateService.getTemplate("json");
        assertNotNull(json);
        assertTrue(json.length > 0);

        byte[] xlsx = templateService.getTemplate("xlsx");
        assertNotNull(xlsx);
        assertTrue(xlsx.length > 0);

        List<AssetFileRecord> parsedFromCsvTemplate = csvParser.parse(new ByteArrayInputStream(csv), "TEST", "TEST");
        assertTrue(parsedFromCsvTemplate.size() >= 3);

        List<AssetFileRecord> parsedFromJsonTemplate = jsonParser.parse(new ByteArrayInputStream(json), "TEST", "TEST");
        assertTrue(parsedFromJsonTemplate.size() >= 3);

        List<AssetFileRecord> parsedFromXlsxTemplate = excelParser.parse(new ByteArrayInputStream(xlsx), "TEST", "TEST");
        assertTrue(parsedFromXlsxTemplate.size() >= 3);
    }

    @Test
    void shouldParseValidLegacyXlsFile() throws Exception {
        byte[] xlsBytes;
        try (Workbook wb = new HSSFWorkbook(); ByteArrayOutputStream bos = new ByteArrayOutputStream()) {
            Sheet sheet = wb.createSheet("Ativos");
            Row header = sheet.createRow(0);
            header.createCell(0).setCellValue("identificador");
            header.createCell(1).setCellValue("tipo_ativo");
            header.createCell(2).setCellValue("latitude");
            header.createCell(3).setCellValue("longitude");

            Row row = sheet.createRow(1);
            row.createCell(0).setCellValue("LEGACY-001");
            row.createCell(1).setCellValue("POSTE");
            row.createCell(2).setCellValue(-23.550520);
            row.createCell(3).setCellValue(-46.633308);

            wb.write(bos);
            xlsBytes = bos.toByteArray();
        }

        List<AssetFileRecord> records = excelParser.parse(new ByteArrayInputStream(xlsBytes), "CPFL", "SUDESTE");
        assertEquals(1, records.size());
        assertEquals("LEGACY-001", records.get(0).assetKey());
        assertEquals("POSTE", records.get(0).assetType());
        assertEquals(-23.550520, records.get(0).latitude(), 0.00001);
        assertEquals(-46.633308, records.get(0).longitude(), 0.00001);
    }

    @Test
    void shouldFailGeoJsonWithMissingAssetType() {
        String geojson = """
                {
                  "type": "FeatureCollection",
                  "features": [
                    {
                      "type": "Feature",
                      "geometry": {
                        "type": "Point",
                        "coordinates": [-46.633308, -23.550520]
                      },
                      "properties": {
                        "identificador": "GEO-NO-TYPE"
                      }
                    }
                  ]
                }
                """;
        InvalidBdgdUploadException ex = assertThrows(InvalidBdgdUploadException.class, () ->
                jsonParser.parse(new ByteArrayInputStream(geojson.getBytes(StandardCharsets.UTF_8)), "CPFL", "SUDESTE")
        );
        assertTrue(ex.getMessage().contains("tipo_ativo"));
    }

    @Test
    void shouldFailGeoJsonWithNonNumericCoordinates() {
        String geojson = """
                {
                  "type": "FeatureCollection",
                  "features": [
                    {
                      "type": "Feature",
                      "geometry": {
                        "type": "Point",
                        "coordinates": ["invalid", "invalid"]
                      },
                      "properties": {
                        "identificador": "GEO-NON-NUM",
                        "tipo_ativo": "POSTE"
                      }
                    }
                  ]
                }
                """;
        InvalidBdgdUploadException ex = assertThrows(InvalidBdgdUploadException.class, () ->
                jsonParser.parse(new ByteArrayInputStream(geojson.getBytes(StandardCharsets.UTF_8)), "CPFL", "SUDESTE")
        );
        assertTrue(ex.getMessage().contains("numéricos"));
    }

    @Test
    void shouldFailCoordinatesWithNonFiniteValues() {
        String csv = """
                identificador,tipo_ativo,latitude,longitude
                POS-100,POSTE,NaN,-46.633308
                """;
        InvalidBdgdUploadException ex = assertThrows(InvalidBdgdUploadException.class, () ->
                csvParser.parse(new ByteArrayInputStream(csv.getBytes(StandardCharsets.UTF_8)), "CPFL", "SUDESTE")
        );
        assertTrue(ex.getMessage().contains("latitude"));
    }

    @Test
    void shouldRecognizeGdbAndTabularZipEntries() {
        assertTrue(com.backend.tecsys.bdgd.service.BdgdUploadValidator.isGdbEntry("Chesp.gdb/a00000001.gdbtable"));
        assertTrue(com.backend.tecsys.bdgd.service.BdgdUploadValidator.isGdbEntry("base/subfolder.gdb/"));
        assertTrue(com.backend.tecsys.bdgd.service.BdgdUploadValidator.isGdbEntry("a00000001.gdbtable"));
        assertTrue(com.backend.tecsys.bdgd.service.BdgdUploadValidator.isGdbEntry("a00000001.gdbindexes"));

        assertTrue(com.backend.tecsys.bdgd.service.BdgdUploadValidator.isTabularEntry("ativos.csv"));
        assertTrue(com.backend.tecsys.bdgd.service.BdgdUploadValidator.isTabularEntry("subfolder/dados.xlsx"));
        assertTrue(com.backend.tecsys.bdgd.service.BdgdUploadValidator.isTabularEntry("assets.json"));
        assertFalse(com.backend.tecsys.bdgd.service.BdgdUploadValidator.isTabularEntry("__MACOSX/._ativos.csv"));
        assertFalse(com.backend.tecsys.bdgd.service.BdgdUploadValidator.isTabularEntry("notes.txt"));
    }

    @Test
    void shouldParseZipContainingCsvAndJson() throws Exception {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (java.util.zip.ZipOutputStream zos = new java.util.zip.ZipOutputStream(baos)) {
            zos.putNextEntry(new java.util.zip.ZipEntry("poste.csv"));
            String csv = "identificador,tipo_ativo,latitude,longitude\nPOS-Z1,POSTE,-23.55,-46.63\n";
            zos.write(csv.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();

            zos.putNextEntry(new java.util.zip.ZipEntry("uc.json"));
            String json = "[{\"identificador\":\"UC-Z1\",\"tipo_ativo\":\"UCBT\",\"latitude\":-23.56,\"longitude\":-46.64}]";
            zos.write(json.getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();
        }

        try (java.util.zip.ZipInputStream zis = new java.util.zip.ZipInputStream(new ByteArrayInputStream(baos.toByteArray()))) {
            java.util.zip.ZipEntry entry;
            List<AssetFileRecord> allRecords = new ArrayList<>();
            while ((entry = zis.getNextEntry()) != null) {
                byte[] bytes = zis.readAllBytes();
                if (entry.getName().endsWith(".csv")) {
                    csvParser.parseAndProcess(new ByteArrayInputStream(bytes), "ENEL", "SP", allRecords::add);
                } else if (entry.getName().endsWith(".json")) {
                    jsonParser.parseAndProcess(new ByteArrayInputStream(bytes), "ENEL", "SP", allRecords::add);
                }
                zis.closeEntry();
            }
            assertEquals(2, allRecords.size());
            assertEquals("POS-Z1", allRecords.get(0).assetKey());
            assertEquals("UC-Z1", allRecords.get(1).assetKey());
        }
    }
}
