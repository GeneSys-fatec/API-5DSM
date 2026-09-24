package com.backend.tecsys.bdgd.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Getter
@Setter
@ConfigurationProperties(prefix = "bdgd.ingestion")
public class BdgdIngestionProperties {
    private long maxUploadBytes = 5368709120L;
    private String storage = "local";
    private String localDirectory = "./data/raw";
    private String bucket = "bdgd-raw";
    private String keyPrefix = "bdgd";
    private String region = "sa-east-1";
    private String n8nWebhookUrl = "http://localhost:5678/webhook/get-etl-data";
}
