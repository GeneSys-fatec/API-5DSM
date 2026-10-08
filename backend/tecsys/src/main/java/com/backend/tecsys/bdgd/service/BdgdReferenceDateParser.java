package com.backend.tecsys.bdgd.service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class BdgdReferenceDateParser {
    private static final Pattern DATE_IN_FILE_NAME = Pattern.compile(
            "(?:^|[_-])(\\d{4}-\\d{2}-\\d{2})(?:[_-]|\\.gdb(?:\\.zip)?$)",
            Pattern.CASE_INSENSITIVE);
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ISO_LOCAL_DATE;

    private BdgdReferenceDateParser() {
    }

    public static LocalDate parseRequired(String fileName) {
        Matcher matcher = DATE_IN_FILE_NAME.matcher(fileName == null ? "" : fileName);
        if (!matcher.find()) {
            throw new IllegalArgumentException(
                    "Nome de arquivo BDGD sem data de referência AAAA-MM-DD: " + fileName);
        }
        try {
            return LocalDate.parse(matcher.group(1), FORMATTER);
        } catch (DateTimeParseException exception) {
            throw new IllegalArgumentException(
                    "Data de referência inválida no nome do arquivo BDGD: " + fileName, exception);
        }
    }

    public static LocalDate parseOrDefault(String fileName, LocalDate fallback) {
        Matcher matcher = DATE_IN_FILE_NAME.matcher(fileName == null ? "" : fileName);
        if (!matcher.find()) {
            return fallback;
        }
        try {
            return LocalDate.parse(matcher.group(1), FORMATTER);
        } catch (DateTimeParseException exception) {
            throw new IllegalArgumentException(
                    "Data de referência inválida no nome do arquivo BDGD: " + fileName, exception);
        }
    }
}