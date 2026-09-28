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
            .version(HttpClient.Version.HTTP_1_1) 
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    public void triggerProcessing(N8nWebhookPayload payload) {
        // 2. Traduzir localhost para 127.0.0.1 para evitar bloqueios de IPv6 no Windows
        String webhookUrl = properties.getN8nWebhookUrl().replace("localhost", "127.0.0.1");
        
        log.info("Enviando webhook N8N para {} com importId={} e gdbPath={}",
                webhookUrl, payload.importId(), payload.gdbPath());

        try {
            String body = objectMapper.writeValueAsString(payload);
            log.info("Payload JSON enviado ao N8N: {}", body);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(webhookUrl))
                    .timeout(Duration.ofSeconds(15))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() >= 200 && response.statusCode() < 300) {
                log.info("Webhook N8N respondeu status={} para importId={}",
                        response.statusCode(), payload.importId());
            } else {
                log.error("Webhook N8N retornou erro status={} para importId={}, body={}",
                        response.statusCode(), payload.importId(), response.body());
            }

        } catch (java.net.http.HttpTimeoutException timeoutException) {
            log.error("Timeout: O N8N não respondeu em 15 segundos. importId={}", payload.importId());
        } catch (Exception exception) {
            log.error("Nao foi possivel disparar webhook N8N em {} para importId={}",
                    webhookUrl, payload.importId(), exception);
            throw new RuntimeException(exception);
        }
    }
}
