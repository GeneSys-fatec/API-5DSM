package com.backend.tecsys.bdgd.service;

import com.backend.tecsys.bdgd.config.BdgdIngestionProperties;
import com.backend.tecsys.bdgd.model.N8nWebhookPayload;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

@Slf4j
@Service
@RequiredArgsConstructor
public class N8nWebhookService {
    private final BdgdIngestionProperties properties;
    private final RestClient restClient = RestClient.create();

    public void triggerProcessing(N8nWebhookPayload payload) {
        String webhookUrl = properties.getN8nWebhookUrl();
        log.info("Enviando webhook N8N para {} com importId={} e gdbPath={}", webhookUrl, payload.importId(), payload.gdbPath());

        try {
            var response = restClient.post()
                .uri(webhookUrl)
                .contentType(MediaType.APPLICATION_JSON)
                .body(payload)
                .retrieve()
                .toEntity(String.class);

            log.info("Webhook N8N respondeu status={} para importId={}, body={}",
                response.getStatusCode().value(), payload.importId(), response.getBody());
        } catch (RestClientResponseException exception) {
            log.error("N8N rejeitou o webhook: status={}, body={}",
                exception.getStatusCode().value(), exception.getResponseBodyAsString(), exception);
            throw exception;
        } catch (Exception exception) {
            log.error("Nao foi possivel conectar ao webhook N8N em {}", webhookUrl, exception);
            throw exception;
        }
    }
}
