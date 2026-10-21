package com.backend.tecsys.scenario.controller;

import com.backend.tecsys.scenario.dto.ScenarioReportRequest;
import com.backend.tecsys.scenario.service.ScenarioReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.nio.charset.StandardCharsets;

@RestController
@RequestMapping("/simulations")
@Tag(name = "Scenario report", description = "Geração de relatórios de cenários.")
public class ScenarioReportController {
    private final ScenarioReportService scenarioReportService;

    public ScenarioReportController(ScenarioReportService scenarioReportService) {
        this.scenarioReportService = scenarioReportService;
    }

    @PostMapping(value = "/{scenarioId}/report", consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_PDF_VALUE)
    @Operation(summary = "Gera um relatório PDF do resultado de um cenário.")
    public ResponseEntity<byte[]> generate(
            @PathVariable Long scenarioId,
            @Valid @RequestBody ScenarioReportRequest request) {
        byte[] report = scenarioReportService.generate(scenarioId, request);
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment()
                        .filename("scenario-" + scenarioId + "-report.pdf", StandardCharsets.UTF_8)
                        .build().toString())
                .body(report);
    }
}
