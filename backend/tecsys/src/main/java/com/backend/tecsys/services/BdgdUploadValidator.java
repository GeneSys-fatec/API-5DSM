package com.backend.tecsys.services;

import com.backend.tecsys.config.BdgdIngestionProperties;
import com.backend.tecsys.exception.InvalidBdgdUploadException;

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
        try {
            if (name.endsWith(".gdb")) {
                return;
            }
            if (!name.endsWith(".zip")) {
                throw new InvalidBdgdUploadException("Formato invalido: use .gdb ou .zip");
            }
            boolean containsGdb = false;
            try (InputStream input = file.getInputStream(); ZipInputStream zip = new ZipInputStream(input)) {
                ZipEntry entry;
                byte[] buffer = new byte[8192];
                while ((entry = zip.getNextEntry()) != null) {
                    if (!entry.isDirectory() && entry.getName().toLowerCase(Locale.ROOT).endsWith(".gdb")) {
                        containsGdb = true;
                    }
                    while (zip.read(buffer) != -1) {
                    }
                    zip.closeEntry();
                }
            }
            if (!containsGdb) {
                throw new InvalidBdgdUploadException("O ZIP deve conter pelo menos um arquivo .gdb");
            }
        } catch (IOException exception) {
            throw new InvalidBdgdUploadException("Arquivo corrompido ou ilegivel");
        }
    }
}