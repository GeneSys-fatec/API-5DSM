package com.backend.tecsys.bdgd.service;

import com.backend.tecsys.bdgd.config.BdgdIngestionProperties;
import com.backend.tecsys.bdgd.model.N8nWebhookPayload;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
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

        restClient.post()
                .uri(webhookUrl)
                .contentType(MediaType.APPLICATION_JSON)
                .body(payload)
                .retrieve()
                .toBodilessEntity();

        log.info("Webhook N8N disparado com sucesso para importId={}", payload.importId());
    }
}
