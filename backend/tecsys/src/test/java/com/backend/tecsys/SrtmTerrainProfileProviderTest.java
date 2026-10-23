package com.backend.tecsys;

import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.radio.model.TerrainProfile;
import com.backend.tecsys.radio.repository.SrtmTerrainProfileProvider;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.URLDecoder;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.zip.GZIPOutputStream;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class SrtmTerrainProfileProviderTest {

    private HttpServer server;

    @AfterEach
    void stopServer() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void shouldLoadAndCacheTerrainProfileFromElevationApi(@TempDir Path cacheDirectory) throws IOException {
        AtomicInteger requests = new AtomicInteger();
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/elevation", exchange -> {
            requests.incrementAndGet();
            String query = URLDecoder.decode(
                    exchange.getRequestURI().getRawQuery(), StandardCharsets.UTF_8);
            String latitudeList = query.substring(
                    query.indexOf("latitude=") + "latitude=".length(),
                    query.indexOf("&longitude="));
            int sampleCount = latitudeList.split(",").length;
            String elevations = java.util.stream.IntStream.range(0, sampleCount)
                    .mapToObj(index -> Integer.toString(100 + index))
                    .collect(java.util.stream.Collectors.joining(","));
            byte[] body = ("{\"elevation\":[" + elevations + "]}")
                    .getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, body.length);
            try (var output = exchange.getResponseBody()) {
                output.write(body);
            }
        });
        server.start();

        SrtmTerrainProfileProvider provider = new SrtmTerrainProfileProvider(
                "",
                "http://127.0.0.1:" + server.getAddress().getPort() + "/elevation",
                "http://127.0.0.1:" + server.getAddress().getPort() + "/srtm",
                cacheDirectory.toString());
        RfCoordinate from = new RfCoordinate(-22.1, -47.1);
        RfCoordinate to = new RfCoordinate(-22.105, -47.105);

        TerrainProfile profile = provider.getProfile(from, to);
        TerrainProfile cached = provider.getProfile(from, to);

        assertTrue(profile.isAvailable());
        assertEquals(5, profile.elevationsMeters().length);
        assertEquals(100.0, profile.elevationsMeters()[0]);
        assertEquals(104.0, profile.elevationsMeters()[4]);
        assertEquals(profile.elevationsMeters()[0], cached.elevationsMeters()[0]);
        assertEquals(1, requests.get());
    }

    @Test
    void shouldReturnAnAvailableProfileWhenEndpointsHaveTheSameCoordinates(
            @TempDir Path cacheDirectory) throws IOException {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/elevation", exchange -> {
            String query = URLDecoder.decode(
                    exchange.getRequestURI().getRawQuery(), StandardCharsets.UTF_8);
            int sampleCount = query.substring(
                    query.indexOf("latitude=") + "latitude=".length(),
                    query.indexOf("&longitude=")).split(",").length;
            byte[] body = ("{\"elevation\":["
                    + java.util.stream.IntStream.range(0, sampleCount)
                            .mapToObj(index -> "100")
                            .collect(java.util.stream.Collectors.joining(","))
                    + "]}").getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(200, body.length);
            try (var output = exchange.getResponseBody()) {
                output.write(body);
            }
        });
        server.start();

        SrtmTerrainProfileProvider provider = new SrtmTerrainProfileProvider(
                "",
                "http://127.0.0.1:" + server.getAddress().getPort() + "/elevation",
                "http://127.0.0.1:" + server.getAddress().getPort() + "/srtm",
                cacheDirectory.toString());
        RfCoordinate coordinate = new RfCoordinate(-22.1, -47.1);

        TerrainProfile profile = provider.getProfile(coordinate, coordinate);

        assertTrue(profile.isAvailable());
        assertEquals(1.0, profile.sampleSpacingM());
        assertEquals(2, profile.elevationsMeters().length);
    }

    @Test
    void shouldDownloadAndCachePublicSrtmTile(@TempDir Path cacheDirectory) throws IOException {
        AtomicInteger tileRequests = new AtomicInteger();
        AtomicInteger elevationApiRequests = new AtomicInteger();
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/skadi/S23/S23W048.hgt.gz", exchange -> {
            tileRequests.incrementAndGet();
            ByteArrayOutputStream compressed = new ByteArrayOutputStream();
            try (GZIPOutputStream gzip = new GZIPOutputStream(compressed)) {
                ByteBuffer rawTile = ByteBuffer.allocate(8).order(ByteOrder.BIG_ENDIAN);
                rawTile.putShort((short) 100);
                rawTile.putShort((short) 110);
                rawTile.putShort((short) 120);
                rawTile.putShort((short) 130);
                gzip.write(rawTile.array());
            }
            byte[] body = compressed.toByteArray();
            exchange.sendResponseHeaders(200, body.length);
            try (var output = exchange.getResponseBody()) {
                output.write(body);
            }
        });
        server.createContext("/elevation", exchange -> {
            elevationApiRequests.incrementAndGet();
            exchange.sendResponseHeaders(500, -1);
            exchange.close();
        });
        server.start();

        String baseUrl = "http://127.0.0.1:" + server.getAddress().getPort();
        SrtmTerrainProfileProvider provider = new SrtmTerrainProfileProvider(
                "",
                baseUrl + "/elevation",
                baseUrl + "/skadi",
                cacheDirectory.toString());
        RfCoordinate from = new RfCoordinate(-22.1, -47.1);
        RfCoordinate to = new RfCoordinate(-22.105, -47.105);

        TerrainProfile profile = provider.getProfile(from, to);
        TerrainProfile cached = provider.getProfile(from, to);

        assertTrue(profile.isAvailable());
        assertEquals(110.0, profile.elevationsMeters()[0]);
        assertEquals(profile.elevationsMeters()[0], cached.elevationsMeters()[0]);
        assertEquals(1, tileRequests.get());
        assertEquals(0, elevationApiRequests.get());
    }
}
