package com.backend.tecsys.services;

import com.backend.tecsys.config.BdgdIngestionProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Locale;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

@Slf4j
@Service
@RequiredArgsConstructor
public class BdgdS3StorageService {
    private final BdgdIngestionProperties properties;
    private final S3Client s3;

    public String store(MultipartFile file, String key) {
        try {
            if ("s3".equalsIgnoreCase(properties.getStorage())) {
                PutObjectRequest request = PutObjectRequest.builder().bucket(properties.getBucket()).key(key)
                        .contentType(file.getContentType()).contentLength(file.getSize()).build();
                try (InputStream input = file.getInputStream()) {
                    s3.putObject(request, RequestBody.fromInputStream(input, file.getSize()));
                }
            } else {
                Path destination = Path.of(properties.getLocalDirectory(), key).toAbsolutePath().normalize();
                Files.createDirectories(destination.getParent());
                try (InputStream input = file.getInputStream()) {
                    Files.copy(input, destination, StandardCopyOption.REPLACE_EXISTING);
                }

                String filename = file.getOriginalFilename() == null ? "" : file.getOriginalFilename().toLowerCase(Locale.ROOT);
                if (filename.endsWith(".zip")) {
                    extractZip(destination, destination.getParent());
                }
            }
            return key;
        } catch (IOException exception) {
            throw new IllegalStateException("Nao foi possivel armazenar o arquivo bruto", exception);
        }
    }

    private void extractZip(Path zipFilePath, Path targetDir) throws IOException {
        log.info("Extraindo arquivo ZIP {} para {}", zipFilePath, targetDir);
        try (InputStream fis = Files.newInputStream(zipFilePath);
             ZipInputStream zis = new ZipInputStream(fis)) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                Path resolvePath = targetDir.resolve(entry.getName()).normalize();
                if (!resolvePath.startsWith(targetDir)) {
                    throw new IOException("Tentativa de travessia de diretorio invalida no ZIP: " + entry.getName());
                }
                if (entry.isDirectory()) {
                    Files.createDirectories(resolvePath);
                } else {
                    Files.createDirectories(resolvePath.getParent());
                    Files.copy(zis, resolvePath, StandardCopyOption.REPLACE_EXISTING);
                }
                zis.closeEntry();
            }
        }
    }

    public Path resolveGdbPath(String key, String fileName) {
        if ("s3".equalsIgnoreCase(properties.getStorage())) {
            return Path.of(properties.getBucket(), key);
        }
        Path parentDir = Path.of(properties.getLocalDirectory(), key).toAbsolutePath().normalize().getParent();
        if (parentDir != null && Files.exists(parentDir)) {
            try (var stream = Files.walk(parentDir)) {
                var gdbDir = stream
                        .filter(p -> p.getFileName() != null && p.getFileName().toString().toLowerCase(Locale.ROOT).endsWith(".gdb"))
                        .findFirst();
                if (gdbDir.isPresent()) {
                    return gdbDir.get();
                }
            } catch (IOException e) {
                log.warn("Erro ao buscar diretorio .gdb em {}: {}", parentDir, e.getMessage());
            }
        }
        return Path.of(properties.getLocalDirectory(), key).toAbsolutePath().normalize();
    }
}