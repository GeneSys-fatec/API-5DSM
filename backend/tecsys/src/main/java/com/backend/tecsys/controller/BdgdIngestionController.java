package com.backend.tecsys.controller;

import com.backend.tecsys.models.BdgdImportResponse;
import com.backend.tecsys.services.BdgdIngestionService;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.util.UUID;

@RestController
@RequestMapping("/api/bdgd/imports")
public class BdgdIngestionController {
    private final BdgdIngestionService service;

    public BdgdIngestionController(BdgdIngestionService service) {
        this.service = service;
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.ACCEPTED)
    public BdgdImportResponse upload(
            @RequestParam("file") MultipartFile file,
            @RequestParam String distribuidora,
            @RequestParam String regiao,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate data) {
        return service.ingest(file, distribuidora, regiao, data);
    }

    @GetMapping("/{id}")
    public BdgdImportResponse status(@PathVariable UUID id) {
        return service.find(id);
    }
}