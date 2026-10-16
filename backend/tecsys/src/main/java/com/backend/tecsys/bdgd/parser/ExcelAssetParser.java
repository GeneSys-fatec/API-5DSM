package com.backend.tecsys.bdgd.parser;

import com.backend.tecsys.bdgd.exception.InvalidBdgdUploadException;
import com.backend.tecsys.bdgd.model.AssetFileRecord;
import org.apache.poi.ss.usermodel.*;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

@Component
public class ExcelAssetParser implements AssetParser {

    @Override
    public List<AssetFileRecord> parse(InputStream inputStream, String defaultDistribuidora, String defaultRegiao) {
        List<AssetFileRecord> result = new ArrayList<>();
        parseAndProcess(inputStream, defaultDistribuidora, defaultRegiao, result::add);
        return result;
    }

    @Override
    public void parseAndProcess(InputStream inputStream, String defaultDistribuidora, String defaultRegiao, java.util.function.Consumer<AssetFileRecord> consumer) {
        try (Workbook workbook = WorkbookFactory.create(inputStream)) {
            if (workbook.getNumberOfSheets() == 0) {
                throw new InvalidBdgdUploadException("A planilha não possui abas de dados.");
            }

            Sheet sheet = workbook.getSheetAt(0);
            int lastRowNum = sheet.getLastRowNum();
            if (lastRowNum < 0) {
                throw new InvalidBdgdUploadException("A planilha está vazia.");
            }

            Row headerRow = sheet.getRow(0);
            if (headerRow == null) {
                throw new InvalidBdgdUploadException("Cabeçalho da planilha ausente.");
            }

            int idCol = -1;
            int typeCol = -1;
            int latCol = -1;
            int lonCol = -1;
            int distCol = -1;
            int regCol = -1;

            int lastCellNum = headerRow.getLastCellNum();
            for (int c = 0; c < lastCellNum; c++) {
                Cell cell = headerRow.getCell(c);
                String cellVal = getCellString(cell);
                String norm = AssetParserUtils.normalizeKey(cellVal);

                if (AssetParserUtils.isIdentifierHeader(norm)) {
                    idCol = c;
                } else if (AssetParserUtils.isTypeHeader(norm)) {
                    typeCol = c;
                } else if (AssetParserUtils.isLatitudeHeader(norm)) {
                    latCol = c;
                } else if (AssetParserUtils.isLongitudeHeader(norm)) {
                    lonCol = c;
                } else if (AssetParserUtils.isDistribuidoraHeader(norm)) {
                    distCol = c;
                } else if (AssetParserUtils.isRegiaoHeader(norm)) {
                    regCol = c;
                }
            }

            List<String> missing = new ArrayList<>();
            if (idCol == -1) missing.add("identificador");
            if (typeCol == -1) missing.add("tipo_ativo");
            if (latCol == -1) missing.add("latitude");
            if (lonCol == -1) missing.add("longitude");

            if (!missing.isEmpty()) {
                throw new InvalidBdgdUploadException(
                        "Cabeçalho da planilha inválido. Colunas obrigatórias ausentes: " + String.join(", ", missing)
                );
            }

            DataFormatter formatter = new DataFormatter();
            int count = 0;

            for (int r = 1; r <= lastRowNum; r++) {
                Row row = sheet.getRow(r);
                int lineNumber = r + 1;
                if (row == null) {
                    continue;
                }

                String rawId = getCellFormatted(row.getCell(idCol), formatter);
                String rawType = getCellFormatted(row.getCell(typeCol), formatter);
                String rawLat = getCellFormatted(row.getCell(latCol), formatter);
                String rawLon = getCellFormatted(row.getCell(lonCol), formatter);
                String rawDist = distCol != -1 ? getCellFormatted(row.getCell(distCol), formatter) : null;
                String rawReg = regCol != -1 ? getCellFormatted(row.getCell(regCol), formatter) : null;

                if (rawId.isEmpty() && rawType.isEmpty() && rawLat.isEmpty() && rawLon.isEmpty()) {
                    continue;
                }

                String assetKey = AssetParserUtils.requireNonBlank(rawId, "identificador", lineNumber);
                String assetType = AssetParserUtils.requireNonBlank(rawType, "tipo_ativo", lineNumber).toUpperCase();
                double latitude = AssetParserUtils.parseLatitude(rawLat, lineNumber);
                double longitude = AssetParserUtils.parseLongitude(rawLon, lineNumber);

                String distribuidora = (rawDist != null && !rawDist.trim().isEmpty()) ? rawDist.trim() : defaultDistribuidora;
                String regiao = (rawReg != null && !rawReg.trim().isEmpty()) ? rawReg.trim() : defaultRegiao;

                consumer.accept(new AssetFileRecord(lineNumber, assetKey, assetType, latitude, longitude, distribuidora, regiao));
                count++;
            }

            if (count == 0) {
                throw new InvalidBdgdUploadException("A planilha não contém registros de ativos válidos.");
            }
        } catch (InvalidBdgdUploadException e) {
            throw e;
        } catch (Exception e) {
            throw new InvalidBdgdUploadException("Falha ao processar arquivo Excel: " + e.getMessage());
        }
    }

    private String getCellString(Cell cell) {
        if (cell == null) {
            return "";
        }
        return cell.getStringCellValue() != null ? cell.getStringCellValue().trim() : "";
    }

    private String getCellFormatted(Cell cell, DataFormatter formatter) {
        if (cell == null) {
            return "";
        }
        return formatter.formatCellValue(cell).trim();
    }
}
