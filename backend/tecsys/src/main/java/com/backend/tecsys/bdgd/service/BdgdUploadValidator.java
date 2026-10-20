package com.backend.tecsys.bdgd.service;

import com.backend.tecsys.bdgd.config.BdgdIngestionProperties;
import com.backend.tecsys.bdgd.exception.InvalidBdgdUploadException;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.util.Locale;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

@Component
@RequiredArgsConstructor
public class BdgdUploadValidator {
    private final BdgdIngestionProperties properties;

    public void validate(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new InvalidBdgdUploadException("O arquivo e obrigatorio");
        }
        if (file.getSize() > properties.getMaxUploadBytes()) {
            throw new InvalidBdgdUploadException("O arquivo excede o tamanho maximo permitido");
        }
        String name = file.getOriginalFilename() == null ? "" : file.getOriginalFilename().toLowerCase(Locale.ROOT);
        if (name.endsWith(".csv") || name.endsWith(".xls") || name.endsWith(".xlsx") || name.endsWith(".json") || name.endsWith(".gdb")) {
            return;
        }

        try {
            if (!name.endsWith(".zip")) {
                throw new InvalidBdgdUploadException("Formato inválido: use .csv, .xls, .xlsx, .json, .gdb ou .zip");
            }
            boolean containsGdb = false;
            boolean containsTabular = false;
            try (InputStream input = file.getInputStream(); ZipInputStream zip = new ZipInputStream(input)) {
                ZipEntry entry;
                byte[] buffer = new byte[8192];
                while ((entry = zip.getNextEntry()) != null) {
                    if (isGdbEntry(entry.getName())) {
                        containsGdb = true;
                    }
                    if (isTabularEntry(entry.getName())) {
                        containsTabular = true;
                    }
                    while (zip.read(buffer) != -1) {
                    }
                    zip.closeEntry();
                }
            }
            if (!containsGdb && !containsTabular) {
                throw new InvalidBdgdUploadException("O ZIP deve conter uma pasta .gdb ou arquivos de dados (.csv, .xls, .xlsx, .json)");
            }
        } catch (IOException exception) {
            throw new InvalidBdgdUploadException("Arquivo corrompido ou ilegível");
        }
    }

    public static boolean isGdbEntry(String entryName) {
        if (entryName == null) return false;
        String normalizedName = entryName.replace('\\', '/').toLowerCase(Locale.ROOT);
        return normalizedName.matches(".*(^|/)[^/]+\\.gdb(/|$).*")
                || normalizedName.endsWith(".gdbtable")
                || normalizedName.endsWith(".gdbindexes");
    }

    public static boolean isTabularEntry(String entryName) {
        if (entryName == null) return false;
        String normalizedName = entryName.replace('\\', '/').toLowerCase(Locale.ROOT);
        if (normalizedName.contains("__macosx") || normalizedName.startsWith(".") || normalizedName.endsWith("/")) {
            return false;
        }
        return normalizedName.endsWith(".csv")
                || normalizedName.endsWith(".xls")
                || normalizedName.endsWith(".xlsx")
                || normalizedName.endsWith(".json");
    }
}
