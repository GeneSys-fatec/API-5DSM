package com.backend.tecsys.services;

import com.backend.tecsys.config.BdgdIngestionProperties;

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

@Service
public class BdgdS3StorageService {
    private final BdgdIngestionProperties properties;
    private final S3Client s3;

    public BdgdS3StorageService(BdgdIngestionProperties properties, S3Client s3) {
        this.properties = properties;
        this.s3 = s3;
    }

    public String store(MultipartFile file, String key) {
        try {
            if ("s3".equalsIgnoreCase(properties.getStorage())) {
                PutObjectRequest request = PutObjectRequest.builder().bucket(properties.getBucket()).key(key)
                        .contentType(file.getContentType()).contentLength(file.getSize()).build();
                try (InputStream input = file.getInputStream()) {
                    s3.putObject(request, RequestBody.fromInputStream(input, file.getSize()));
                }
            } else {
                Path destination = Path.of(properties.getLocalDirectory(), key);
                Files.createDirectories(destination.getParent());
                try (InputStream input = file.getInputStream()) {
                    Files.copy(input, destination, StandardCopyOption.REPLACE_EXISTING);
                }
            }
            return key;
        } catch (IOException exception) {
            throw new IllegalStateException("Nao foi possivel armazenar o arquivo bruto", exception);
        }
    }
}