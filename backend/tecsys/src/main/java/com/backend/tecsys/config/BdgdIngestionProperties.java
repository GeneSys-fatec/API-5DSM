package com.backend.tecsys.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "bdgd.ingestion")
public class BdgdIngestionProperties {
    private long maxUploadBytes = 5368709120L;
    private String storage = "local";
    private String localDirectory = "./data/raw";
    private String bucket = "bdgd-raw";
    private String keyPrefix = "bdgd";
    private String region = "sa-east-1";

    public long getMaxUploadBytes() { return maxUploadBytes; }
    public void setMaxUploadBytes(long maxUploadBytes) { this.maxUploadBytes = maxUploadBytes; }
    public String getStorage() { return storage; }
    public void setStorage(String storage) { this.storage = storage; }
    public String getLocalDirectory() { return localDirectory; }
    public void setLocalDirectory(String localDirectory) { this.localDirectory = localDirectory; }
    public String getBucket() { return bucket; }
    public void setBucket(String bucket) { this.bucket = bucket; }
    public String getKeyPrefix() { return keyPrefix; }
    public void setKeyPrefix(String keyPrefix) { this.keyPrefix = keyPrefix; }
    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }
}