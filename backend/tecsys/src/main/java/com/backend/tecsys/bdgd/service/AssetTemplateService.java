package com.backend.tecsys.bdgd.service;

import com.backend.tecsys.bdgd.exception.InvalidBdgdUploadException;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

@Service
public class AssetTemplateService {

    public byte[] getTemplate(String format) {
        String normalized = format == null ? "" : format.trim().toLowerCase();
        return switch (normalized) {
            case "csv" -> getCsvTemplate();
            case "json" -> getJsonTemplate();
            case "xlsx", "xls" -> getXlsxTemplate();
            default -> throw new InvalidBdgdUploadException("Formato de template desconhecido: " + format + ". Formatos válidos: csv, xlsx, json.");
        };
    }

    public String getFilename(String format) {
        String normalized = format == null ? "" : format.trim().toLowerCase();
        return switch (normalized) {
            case "csv" -> "exemplo_ativos_bdgd.csv";
            case "json" -> "exemplo_ativos_bdgd.json";
            case "xlsx", "xls" -> "exemplo_ativos_bdgd.xlsx";
            default -> "exemplo_ativos." + format;
        };
    }

    public String getContentType(String format) {
        String normalized = format == null ? "" : format.trim().toLowerCase();
        return switch (normalized) {
            case "csv" -> "text/csv; charset=utf-8";
            case "json" -> "application/json; charset=utf-8";
            case "xlsx", "xls" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
            default -> "application/octet-stream";
        };
    }

    private byte[] getCsvTemplate() {
        String csv = """
                identificador,tipo_ativo,latitude,longitude,distribuidora,regiao
                POS-001,POSTE,-23.550520,-46.633308,CPFL,SUDESTE
                TR-002,TRAFO,-23.551200,-46.634100,CPFL,SUDESTE
                REL-003,RELIGADOR,-23.552100,-46.635200,CPFL,SUDESTE
                SUB-004,SUBESTACAO,-23.553000,-46.636000,CPFL,SUDESTE
                UC-005,UCBT,-23.550800,-46.632500,CPFL,SUDESTE
                """;
        return csv.getBytes(StandardCharsets.UTF_8);
    }

    private byte[] getJsonTemplate() {
        String json = """
                [
                  {
                    "identificador": "POS-001",
                    "tipo_ativo": "POSTE",
                    "latitude": -23.550520,
                    "longitude": -46.633308,
                    "distribuidora": "CPFL",
                    "regiao": "SUDESTE"
                  },
                  {
                    "identificador": "TR-002",
                    "tipo_ativo": "TRAFO",
                    "latitude": -23.551200,
                    "longitude": -46.634100,
                    "distribuidora": "CPFL",
                    "regiao": "SUDESTE"
                  },
                  {
                    "identificador": "REL-003",
                    "tipo_ativo": "RELIGADOR",
                    "latitude": -23.552100,
                    "longitude": -46.635200,
                    "distribuidora": "CPFL",
                    "regiao": "SUDESTE"
                  },
                  {
                    "identificador": "SUB-004",
                    "tipo_ativo": "SUBESTACAO",
                    "latitude": -23.553000,
                    "longitude": -46.636000,
                    "distribuidora": "CPFL",
                    "regiao": "SUDESTE"
                  },
                  {
                    "identificador": "UC-005",
                    "tipo_ativo": "UCBT",
                    "latitude": -23.550800,
                    "longitude": -46.632500,
                    "distribuidora": "CPFL",
                    "regiao": "SUDESTE"
                  }
                ]
                """;
        return json.getBytes(StandardCharsets.UTF_8);
    }

    private byte[] getXlsxTemplate() {
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream bos = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Ativos");

            Font headerFont = workbook.createFont();
            headerFont.setBold(true);
            headerFont.setColor(IndexedColors.WHITE.getIndex());

            CellStyle headerStyle = workbook.createCellStyle();
            headerStyle.setFont(headerFont);
            headerStyle.setFillForegroundColor(IndexedColors.DARK_BLUE.getIndex());
            headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
            headerStyle.setAlignment(HorizontalAlignment.CENTER);

            String[] headers = {"identificador", "tipo_ativo", "latitude", "longitude", "distribuidora", "regiao"};
            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }

            Object[][] sampleData = {
                    {"POS-001", "POSTE", -23.550520, -46.633308, "CPFL", "SUDESTE"},
                    {"TR-002", "TRAFO", -23.551200, -46.634100, "CPFL", "SUDESTE"},
                    {"REL-003", "RELIGADOR", -23.552100, -46.635200, "CPFL", "SUDESTE"},
                    {"SUB-004", "SUBESTACAO", -23.553000, -46.636000, "CPFL", "SUDESTE"},
                    {"UC-005", "UCBT", -23.550800, -46.632500, "CPFL", "SUDESTE"}
            };

            for (int r = 0; r < sampleData.length; r++) {
                Row row = sheet.createRow(r + 1);
                for (int c = 0; c < sampleData[r].length; c++) {
                    Cell cell = row.createCell(c);
                    Object val = sampleData[r][c];
                    if (val instanceof Double d) {
                        cell.setCellValue(d);
                    } else if (val instanceof String s) {
                        cell.setCellValue(s);
                    }
                }
            }

            for (int i = 0; i < headers.length; i++) {
                sheet.autoSizeColumn(i);
            }

            workbook.write(bos);
            return bos.toByteArray();
        } catch (IOException e) {
            throw new IllegalStateException("Falha ao gerar arquivo modelo XLSX", e);
        }
    }
}
