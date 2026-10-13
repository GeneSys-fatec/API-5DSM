package com.backend.tecsys.bdgd.parser;

import com.backend.tecsys.bdgd.exception.InvalidBdgdUploadException;
import com.backend.tecsys.bdgd.model.AssetFileRecord;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

@Component
public class JsonAssetParser implements AssetParser {

    private final ObjectMapper objectMapper;

    public JsonAssetParser(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public List<AssetFileRecord> parse(InputStream inputStream, String defaultDistribuidora, String defaultRegiao) {
        try {
            JsonNode root = objectMapper.readTree(inputStream);
            if (root == null || root.isEmpty()) {
                throw new InvalidBdgdUploadException("O arquivo JSON está vazio.");
            }

            JsonNode arrayNode = null;
            boolean isGeoJson = false;

            if (root.isArray()) {
                arrayNode = root;
            } else if (root.isObject()) {
                if (root.has("type") && "FeatureCollection".equalsIgnoreCase(root.get("type").asText()) && root.has("features") && root.get("features").isArray()) {
                    arrayNode = root.get("features");
                    isGeoJson = true;
                } else if (root.has("ativos") && root.get("ativos").isArray()) {
                    arrayNode = root.get("ativos");
                } else if (root.has("assets") && root.get("assets").isArray()) {
                    arrayNode = root.get("assets");
                } else if (root.has("data") && root.get("data").isArray()) {
                    arrayNode = root.get("data");
                } else {
                    throw new InvalidBdgdUploadException(
                            "Estrutura JSON inválida. O arquivo deve ser uma lista de ativos [ ... ] ou conter um campo 'ativos' ou ser um GeoJSON FeatureCollection."
                    );
                }
            } else {
                throw new InvalidBdgdUploadException("O arquivo JSON deve conter um array ou objeto válido.");
            }

            if (arrayNode == null || arrayNode.isEmpty()) {
                throw new InvalidBdgdUploadException("O arquivo JSON não contém registros de ativos.");
            }

            List<AssetFileRecord> result = new ArrayList<>();
            int itemIndex = 1;

            for (JsonNode item : arrayNode) {
                if (isGeoJson) {
                    result.add(parseGeoJsonFeature(item, itemIndex, defaultDistribuidora, defaultRegiao));
                } else {
                    result.add(parseStandardJsonObject(item, itemIndex, defaultDistribuidora, defaultRegiao));
                }
                itemIndex++;
            }

            return result;
        } catch (InvalidBdgdUploadException e) {
            throw e;
        } catch (Exception e) {
            throw new InvalidBdgdUploadException("Falha ao processar arquivo JSON: " + e.getMessage());
        }
    }

    private AssetFileRecord parseStandardJsonObject(JsonNode node, int itemIndex, String defaultDistribuidora, String defaultRegiao) {
        if (!node.isObject()) {
            throw new InvalidBdgdUploadException("Erro no item " + itemIndex + ": o registro deve ser um objeto JSON.");
        }

        String rawId = null;
        String rawType = null;
        String rawLat = null;
        String rawLon = null;
        String rawDist = null;
        String rawReg = null;

        Iterator<String> fieldNames = node.fieldNames();
        while (fieldNames.hasNext()) {
            String field = fieldNames.next();
            String norm = AssetParserUtils.normalizeKey(field);
            JsonNode val = node.get(field);
            String textVal = val.isNull() ? null : val.asText();

            if (AssetParserUtils.isIdentifierHeader(norm)) {
                rawId = textVal;
            } else if (AssetParserUtils.isTypeHeader(norm)) {
                rawType = textVal;
            } else if (AssetParserUtils.isLatitudeHeader(norm)) {
                rawLat = textVal;
            } else if (AssetParserUtils.isLongitudeHeader(norm)) {
                rawLon = textVal;
            } else if (AssetParserUtils.isDistribuidoraHeader(norm)) {
                rawDist = textVal;
            } else if (AssetParserUtils.isRegiaoHeader(norm)) {
                rawReg = textVal;
            }
        }

        String assetKey = AssetParserUtils.requireNonBlank(rawId, "identificador", itemIndex);
        String assetType = AssetParserUtils.requireNonBlank(rawType, "tipo_ativo", itemIndex).toUpperCase();
        double latitude = AssetParserUtils.parseLatitude(rawLat, itemIndex);
        double longitude = AssetParserUtils.parseLongitude(rawLon, itemIndex);

        String distribuidora = (rawDist != null && !rawDist.trim().isEmpty()) ? rawDist.trim() : defaultDistribuidora;
        String regiao = (rawReg != null && !rawReg.trim().isEmpty()) ? rawReg.trim() : defaultRegiao;

        return new AssetFileRecord(itemIndex, assetKey, assetType, latitude, longitude, distribuidora, regiao);
    }

    private AssetFileRecord parseGeoJsonFeature(JsonNode featureNode, int itemIndex, String defaultDistribuidora, String defaultRegiao) {
        JsonNode geom = featureNode.get("geometry");
        if (geom == null || !geom.has("coordinates")) {
            throw new InvalidBdgdUploadException("Erro no item " + itemIndex + ": geometria GeoJSON ausente ou sem 'coordinates'.");
        }

        JsonNode coords = geom.get("coordinates");
        if (!coords.isArray() || coords.size() < 2) {
            throw new InvalidBdgdUploadException("Erro no item " + itemIndex + ": coordenadas do ponto devem conter [longitude, latitude].");
        }

        double longitude = coords.get(0).asDouble();
        double latitude = coords.get(1).asDouble();

        if (latitude < -90.0 || latitude > 90.0) {
            throw new InvalidBdgdUploadException("Erro no item " + itemIndex + ": latitude " + latitude + " fora dos limites (-90 a 90).");
        }
        if (longitude < -180.0 || longitude > 180.0) {
            throw new InvalidBdgdUploadException("Erro no item " + itemIndex + ": longitude " + longitude + " fora dos limites (-180 a 180).");
        }

        JsonNode props = featureNode.get("properties");
        String rawId = null;
        String rawType = null;
        String rawDist = null;
        String rawReg = null;

        if (props != null && props.isObject()) {
            Iterator<String> fieldNames = props.fieldNames();
            while (fieldNames.hasNext()) {
                String field = fieldNames.next();
                String norm = AssetParserUtils.normalizeKey(field);
                JsonNode val = props.get(field);
                String textVal = val.isNull() ? null : val.asText();

                if (AssetParserUtils.isIdentifierHeader(norm)) {
                    rawId = textVal;
                } else if (AssetParserUtils.isTypeHeader(norm)) {
                    rawType = textVal;
                } else if (AssetParserUtils.isDistribuidoraHeader(norm)) {
                    rawDist = textVal;
                } else if (AssetParserUtils.isRegiaoHeader(norm)) {
                    rawReg = textVal;
                }
            }
        }

        if (rawId == null && featureNode.has("id")) {
            rawId = featureNode.get("id").asText();
        }

        String assetKey = AssetParserUtils.requireNonBlank(rawId, "identificador", itemIndex);
        String assetType = rawType != null && !rawType.trim().isEmpty() ? rawType.trim().toUpperCase() : "POSTE";

        String distribuidora = (rawDist != null && !rawDist.trim().isEmpty()) ? rawDist.trim() : defaultDistribuidora;
        String regiao = (rawReg != null && !rawReg.trim().isEmpty()) ? rawReg.trim() : defaultRegiao;

        return new AssetFileRecord(itemIndex, assetKey, assetType, latitude, longitude, distribuidora, regiao);
    }
}
