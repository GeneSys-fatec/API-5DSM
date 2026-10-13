package com.backend.tecsys.bdgd.parser;

import com.backend.tecsys.bdgd.exception.InvalidBdgdUploadException;
import com.backend.tecsys.bdgd.model.AssetFileRecord;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

@Component
public class CsvAssetParser implements AssetParser {

    @Override
    public List<AssetFileRecord> parse(InputStream inputStream, String defaultDistribuidora, String defaultRegiao) {
        try {
            BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8));
            reader.mark(1024 * 1024);
            String firstLine = reader.readLine();
            if (firstLine == null || firstLine.trim().isEmpty()) {
                throw new InvalidBdgdUploadException("O arquivo CSV está vazio.");
            }
            reader.reset();

            char delimiter = firstLine.contains(";") && !firstLine.contains(",") ? ';' : ',';

            CSVFormat format = CSVFormat.DEFAULT.builder()
                    .setDelimiter(delimiter)
                    .setTrim(true)
                    .setIgnoreEmptyLines(true)
                    .build();

            CSVParser parser = format.parse(reader);
            List<CSVRecord> records = parser.getRecords();

            if (records.isEmpty()) {
                throw new InvalidBdgdUploadException("O arquivo CSV está vazio.");
            }

            CSVRecord headerRecord = records.get(0);
            int idCol = -1;
            int typeCol = -1;
            int latCol = -1;
            int lonCol = -1;
            int distCol = -1;
            int regCol = -1;

            for (int i = 0; i < headerRecord.size(); i++) {
                String norm = AssetParserUtils.normalizeKey(headerRecord.get(i));
                if (AssetParserUtils.isIdentifierHeader(norm)) {
                    idCol = i;
                } else if (AssetParserUtils.isTypeHeader(norm)) {
                    typeCol = i;
                } else if (AssetParserUtils.isLatitudeHeader(norm)) {
                    latCol = i;
                } else if (AssetParserUtils.isLongitudeHeader(norm)) {
                    lonCol = i;
                } else if (AssetParserUtils.isDistribuidoraHeader(norm)) {
                    distCol = i;
                } else if (AssetParserUtils.isRegiaoHeader(norm)) {
                    regCol = i;
                }
            }

            List<String> missing = new ArrayList<>();
            if (idCol == -1) missing.add("identificador");
            if (typeCol == -1) missing.add("tipo_ativo");
            if (latCol == -1) missing.add("latitude");
            if (lonCol == -1) missing.add("longitude");

            if (!missing.isEmpty()) {
                throw new InvalidBdgdUploadException(
                        "Cabeçalho do CSV inválido. Colunas obrigatórias ausentes: " + String.join(", ", missing)
                );
            }

            if (records.size() <= 1) {
                throw new InvalidBdgdUploadException("O arquivo CSV contém apenas cabeçalho e nenhum registro de ativo.");
            }

            List<AssetFileRecord> result = new ArrayList<>();
            for (int r = 1; r < records.size(); r++) {
                CSVRecord record = records.get(r);
                int lineNumber = r + 1;

                if (record.size() == 0 || (record.size() == 1 && record.get(0).trim().isEmpty())) {
                    continue;
                }

                String rawId = idCol < record.size() ? record.get(idCol) : null;
                String rawType = typeCol < record.size() ? record.get(typeCol) : null;
                String rawLat = latCol < record.size() ? record.get(latCol) : null;
                String rawLon = lonCol < record.size() ? record.get(lonCol) : null;
                String rawDist = distCol != -1 && distCol < record.size() ? record.get(distCol) : null;
                String rawReg = regCol != -1 && regCol < record.size() ? record.get(regCol) : null;

                String assetKey = AssetParserUtils.requireNonBlank(rawId, "identificador", lineNumber);
                String assetType = AssetParserUtils.requireNonBlank(rawType, "tipo_ativo", lineNumber).toUpperCase();
                double latitude = AssetParserUtils.parseLatitude(rawLat, lineNumber);
                double longitude = AssetParserUtils.parseLongitude(rawLon, lineNumber);

                String distribuidora = (rawDist != null && !rawDist.trim().isEmpty()) ? rawDist.trim() : defaultDistribuidora;
                String regiao = (rawReg != null && !rawReg.trim().isEmpty()) ? rawReg.trim() : defaultRegiao;

                result.add(new AssetFileRecord(lineNumber, assetKey, assetType, latitude, longitude, distribuidora, regiao));
            }

            if (result.isEmpty()) {
                throw new InvalidBdgdUploadException("O arquivo CSV não contém registros válidos.");
            }

            return result;
        } catch (InvalidBdgdUploadException e) {
            throw e;
        } catch (Exception e) {
            throw new InvalidBdgdUploadException("Falha ao processar arquivo CSV: " + e.getMessage());
        }
    }
}
