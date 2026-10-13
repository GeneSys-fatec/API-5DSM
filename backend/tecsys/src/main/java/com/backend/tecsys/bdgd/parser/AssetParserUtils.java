package com.backend.tecsys.bdgd.parser;

import com.backend.tecsys.bdgd.exception.InvalidBdgdUploadException;

import java.text.Normalizer;
import java.util.Locale;

public final class AssetParserUtils {

    private AssetParserUtils() {
    }

    public static String normalizeKey(String text) {
        if (text == null) {
            return "";
        }
        String normalized = Normalizer.normalize(text.trim(), Normalizer.Form.NFD);
        normalized = normalized.replaceAll("\\p{M}", "");
        return normalized.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]", "");
    }

    public static boolean isIdentifierHeader(String norm) {
        return norm.equals("identificador")
                || norm.equals("id")
                || norm.equals("assetkey")
                || norm.equals("codigo")
                || norm.equals("codativo")
                || norm.equals("key");
    }

    public static boolean isTypeHeader(String norm) {
        return norm.equals("tipoativo")
                || norm.equals("tipo")
                || norm.equals("assettype")
                || norm.equals("categoria")
                || norm.equals("classificacao");
    }

    public static boolean isLatitudeHeader(String norm) {
        return norm.equals("latitude")
                || norm.equals("lat")
                || norm.equals("coordy")
                || norm.equals("y");
    }

    public static boolean isLongitudeHeader(String norm) {
        return norm.equals("longitude")
                || norm.equals("long")
                || norm.equals("lon")
                || norm.equals("lng")
                || norm.equals("coordx")
                || norm.equals("x");
    }

    public static boolean isDistribuidoraHeader(String norm) {
        return norm.equals("distribuidora")
                || norm.equals("distribuidoraid")
                || norm.equals("concessionaria")
                || norm.equals("dist");
    }

    public static boolean isRegiaoHeader(String norm) {
        return norm.equals("regiao")
                || norm.equals("region");
    }

    public static String requireNonBlank(String value, String fieldName, int rowNumber) {
        if (value == null || value.trim().isEmpty()) {
            throw new InvalidBdgdUploadException(
                    "Erro na linha " + rowNumber + ": campo '" + fieldName + "' é obrigatório."
            );
        }
        return value.trim();
    }

    public static double parseLatitude(String value, int rowNumber) {
        if (value == null || value.trim().isEmpty()) {
            throw new InvalidBdgdUploadException(
                    "Erro na linha " + rowNumber + ": campo 'latitude' é obrigatório."
            );
        }
        String sanitized = value.trim().replace(',', '.');
        try {
            double lat = Double.parseDouble(sanitized);
            if (lat < -90.0 || lat > 90.0) {
                throw new InvalidBdgdUploadException(
                        "Erro na linha " + rowNumber + ": campo 'latitude' com valor '" + value + "' fora dos limites permitidos (-90.0 a 90.0)."
                );
            }
            return lat;
        } catch (NumberFormatException e) {
            throw new InvalidBdgdUploadException(
                    "Erro na linha " + rowNumber + ": campo 'latitude' inválido ou ausente: '" + value + "'. O valor deve ser numérico."
            );
        }
    }

    public static double parseLongitude(String value, int rowNumber) {
        if (value == null || value.trim().isEmpty()) {
            throw new InvalidBdgdUploadException(
                    "Erro na linha " + rowNumber + ": campo 'longitude' é obrigatório."
            );
        }
        String sanitized = value.trim().replace(',', '.');
        try {
            double lon = Double.parseDouble(sanitized);
            if (lon < -180.0 || lon > 180.0) {
                throw new InvalidBdgdUploadException(
                        "Erro na linha " + rowNumber + ": campo 'longitude' com valor '" + value + "' fora dos limites permitidos (-180.0 a 180.0)."
                );
            }
            return lon;
        } catch (NumberFormatException e) {
            throw new InvalidBdgdUploadException(
                    "Erro na linha " + rowNumber + ": campo 'longitude' inválido ou ausente: '" + value + "'. O valor deve ser numérico."
            );
        }
    }
}
