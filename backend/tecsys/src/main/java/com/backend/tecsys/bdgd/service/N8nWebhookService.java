package com.backend.tecsys.bdgd.service;

import com.backend.tecsys.bdgd.config.BdgdIngestionProperties;
import com.backend.tecsys.bdgd.model.N8nWebhookPayload;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

@Slf4j
@Service
@RequiredArgsConstructor
public class N8nWebhookService {
    private final BdgdIngestionProperties properties;

    private final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    public void triggerProcessing(N8nWebhookPayload payload) {
        String webhookUrl = properties.getN8nWebhookUrl();
        log.info("Enviando webhook N8N (fire-and-forget) para {} com importId={} e gdbPath={}",
                webhookUrl, payload.importId(), payload.gdbPath());

        try {
            String body = objectMapper.writeValueAsString(payload);
            log.info("Payload JSON enviado ao N8N: {}", body);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(webhookUrl))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build();

            // Fire-and-forget: envia de forma assíncrona e não bloqueia aguardando o ETL terminar
            httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofString())
                    .thenAccept(response -> {
                        if (response.statusCode() >= 200 && response.statusCode() < 300) {
                            log.info("Webhook N8N respondeu status={} para importId={}",
                                    response.statusCode(), payload.importId());
                        } else {
                            log.error("Webhook N8N retornou erro status={} para importId={}, body={}",
                                    response.statusCode(), payload.importId(), response.body());
                        }
                    })
                    .exceptionally(ex -> {
                        log.warn("Webhook N8N nao respondeu para importId={}: {}",
                                payload.importId(), ex.getMessage());
                        return null;
                    });

        } catch (Exception exception) {
            log.error("Nao foi possivel disparar webhook N8N em {} para importId={}",
                    webhookUrl, payload.importId(), exception);
            throw new RuntimeException(exception);
        }
    }
}
