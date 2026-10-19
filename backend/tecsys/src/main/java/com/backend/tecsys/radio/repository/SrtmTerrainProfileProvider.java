package com.backend.tecsys.radio.repository;

import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.radio.model.TerrainProfile;
import com.backend.tecsys.radio.exception.UnavailableTerrainDataException;
import com.backend.tecsys.radio.service.GeoDistanceCalculator;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.file.AtomicMoveNotSupportedException;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.zip.GZIPInputStream;

@Component
@Slf4j
public class SrtmTerrainProfileProvider implements TerrainProfileProvider {
    private static final int MAX_SAMPLES = 64;
    private static final double MINIMUM_PROFILE_DISTANCE_M = 1.0;
    private final Path directory;
    private final Path cacheDirectory;
    private final String elevationApiUrl;
    private final String srtmBaseUrl;
    private final Map<Path, Optional<short[]>> tileCache = new ConcurrentHashMap<>();
    private final Map<Path, Integer> resolutionCache = new ConcurrentHashMap<>();
    private final Map<ProfileKey, TerrainProfile> profileCache = new ConcurrentHashMap<>();
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    public SrtmTerrainProfileProvider(
            @Value("${terrain.srtm-directory:}") String directory,
            @Value("${terrain.elevation-api-url:https://api.open-meteo.com/v1/elevation}") String elevationApiUrl,
            @Value("${terrain.srtm-base-url:https://elevation-tiles-prod.s3.amazonaws.com/skadi}") String srtmBaseUrl,
            @Value("${terrain.srtm-cache-directory:}") String cacheDirectory) {
        this.directory = directory == null || directory.isBlank() ? null : Path.of(directory);
        this.elevationApiUrl = elevationApiUrl;
        this.srtmBaseUrl = srtmBaseUrl;
        this.cacheDirectory = cacheDirectory == null || cacheDirectory.isBlank()
                ? Path.of(System.getProperty("java.io.tmpdir"), "tecsys-srtm")
                : Path.of(cacheDirectory);
    }

    @Override
    public TerrainProfile getProfile(RfCoordinate from, RfCoordinate to) {
        ProfileKey key = new ProfileKey(from, to);
        TerrainProfile cachedProfile = profileCache.get(key);
        if (cachedProfile != null) {
            return cachedProfile;
        }

        double distance = Math.max(
                GeoDistanceCalculator.distanceMeters(from, to),
                MINIMUM_PROFILE_DISTANCE_M);
        int sampleCount = Math.max(2, Math.min(MAX_SAMPLES, (int) Math.ceil(distance / 250.0) + 1));
        double spacing = distance / (sampleCount - 1);
        double[] elevations = new double[sampleCount];
        List<Double> latitudes = new ArrayList<>(sampleCount);
        List<Double> longitudes = new ArrayList<>(sampleCount);
        boolean localProfileAvailable = true;

        for (int index = 0; index < sampleCount; index++) {
            double fraction = index / (double) (sampleCount - 1);
            double latitude = from.latitude() + (to.latitude() - from.latitude()) * fraction;
            double longitude = from.longitude() + (to.longitude() - from.longitude()) * fraction;
            latitudes.add(latitude);
            longitudes.add(longitude);
            if (localProfileAvailable) {
                Double elevation = readElevation(latitude, longitude);
                if (elevation == null) {
                    localProfileAvailable = false;
                } else {
                    elevations[index] = elevation;
                }
            }
        }

        if (!localProfileAvailable) {
            elevations = loadElevationsFromApi(latitudes, longitudes);
        }

        TerrainProfile profile = new TerrainProfile(elevations, spacing);
        profileCache.putIfAbsent(key, profile);
        return profile;
    }

    private double[] loadElevationsFromApi(List<Double> latitudes, List<Double> longitudes) {
        String latitudeParameter = encodeCoordinates(latitudes);
        String longitudeParameter = encodeCoordinates(longitudes);
        String separator = elevationApiUrl.contains("?") ? "&" : "?";
        URI uri = URI.create(elevationApiUrl + separator
                + "latitude=" + latitudeParameter
                + "&longitude=" + longitudeParameter);
        HttpRequest request = HttpRequest.newBuilder(uri)
                .timeout(Duration.ofSeconds(20))
                .header("Accept", "application/json")
                .GET()
                .build();

        try {
            HttpResponse<String> response = httpClient.send(
                    request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) {
                throw new IOException("Elevation API returned HTTP " + response.statusCode());
            }

            JsonNode elevationValues = objectMapper.readTree(response.body()).path("elevation");
            if (!elevationValues.isArray() || elevationValues.size() != latitudes.size()) {
                throw new IOException("Elevation API returned an invalid number of samples");
            }

            double[] elevations = new double[elevationValues.size()];
            for (int index = 0; index < elevations.length; index++) {
                JsonNode value = elevationValues.get(index);
                if (value == null || !value.isNumber() || !Double.isFinite(value.doubleValue())) {
                    throw new IOException("Elevation API returned an invalid elevation sample");
                }
                elevations[index] = value.doubleValue();
            }
            return elevations;
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new UnavailableTerrainDataException(
                    "A consulta do relevo foi interrompida. Tente novamente.", exception);
        } catch (IOException | IllegalArgumentException exception) {
            log.warn("Não foi possível obter o perfil de elevação da API pública: {}",
                    exception.getClass().getSimpleName());
            throw new UnavailableTerrainDataException(
                    "Não foi possível carregar o perfil de relevo. Verifique a conexão com o serviço de elevação.",
                    exception);
        }
    }

    private String encodeCoordinates(List<Double> coordinates) {
        String values = coordinates.stream()
                .map(String::valueOf)
                .collect(java.util.stream.Collectors.joining(","));
        return URLEncoder.encode(values, StandardCharsets.UTF_8);
    }

    private Double readElevation(double latitude, double longitude) {
        int latitudeTile = (int) Math.floor(latitude);
        int longitudeTile = (int) Math.floor(longitude);
        String tileName = tileName(latitudeTile, longitudeTile);
        Path localTile = directory == null ? null : directory.resolve(tileName);
        Path cachedTile = cacheDirectory.resolve(tileName);
        Path tile = localTile != null && Files.isRegularFile(localTile) ? localTile : cachedTile;
        try {
            Optional<short[]> tileValues = tileCache.computeIfAbsent(
                    tile, path -> Optional.ofNullable(loadTile(path)));
            if (tileValues.isEmpty()) {
                return null;
            }
            short[] values = tileValues.get();
            int resolution = resolutionCache.computeIfAbsent(tile, ignored -> (int) Math.sqrt(values.length) - 1);
            int column = Math.max(0, Math.min(resolution, (int) Math.round((longitude - longitudeTile) * resolution)));
            int row = Math.max(0, Math.min(resolution, (int) Math.round((latitudeTile + 1.0 - latitude) * resolution)));
            int value = values[row * (resolution + 1) + column];
            return value == Short.MIN_VALUE ? null : (double) value;
        } catch (RuntimeException exception) {
            return null;
        }
    }

    private short[] loadTile(Path tile) {
        short[] values = readTile(tile);
        if (values != null) {
            return values;
        }

        Path cachedTile = cacheDirectory.resolve(tile.getFileName());
        if (!cachedTile.equals(tile)) {
            values = readTile(cachedTile);
            if (values != null) {
                return values;
            }
        }

        try {
            downloadTile(cachedTile);
            return readTile(cachedTile);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            log.warn("Download do mosaico SRTM interrompido.");
            return null;
        } catch (IOException exception) {
            log.warn("Não foi possível carregar o mosaico SRTM: {}", exception.getMessage());
            return null;
        }
    }

    private short[] readTile(Path tile) {
        try {
            byte[] bytes = Files.readAllBytes(tile);
            if (bytes.length < 2 || bytes.length % 2 != 0) {
                return null;
            }
            short[] values = new short[bytes.length / 2];
            ByteBuffer buffer = ByteBuffer.wrap(bytes).order(ByteOrder.BIG_ENDIAN);
            buffer.asShortBuffer().get(values);
            int resolution = (int) Math.sqrt(values.length) - 1;
            return resolution > 0 && (resolution + 1) * (resolution + 1) == values.length
                    ? values
                    : null;
        } catch (IOException exception) {
            return null;
        }
    }

    private void downloadTile(Path tile) throws IOException, InterruptedException {
        String filename = tile.getFileName().toString();
        String region = filename.substring(0, 3);
        URI uri = URI.create(srtmBaseUrl + "/" + region + "/" + filename + ".gz");
        HttpRequest request = HttpRequest.newBuilder(uri)
                .timeout(Duration.ofSeconds(60))
                .header("Accept", "application/gzip")
                .GET()
                .build();
        HttpResponse<InputStream> response = httpClient.send(
                request, HttpResponse.BodyHandlers.ofInputStream());
        if (response.statusCode() != 200) {
            try (InputStream body = response.body()) {
                body.transferTo(java.io.OutputStream.nullOutputStream());
            }
            throw new IOException("HTTP " + response.statusCode());
        }

        Files.createDirectories(cacheDirectory);
        Path temporaryTile = Files.createTempFile(cacheDirectory, filename, ".tmp");
        try {
            try (InputStream responseBody = response.body();
                 GZIPInputStream decompressed = new GZIPInputStream(responseBody)) {
                Files.copy(decompressed, temporaryTile, StandardCopyOption.REPLACE_EXISTING);
            }
            if (readTile(temporaryTile) == null) {
                throw new IOException("O mosaico SRTM baixado possui formato inválido.");
            }
            try {
                Files.move(
                        temporaryTile,
                        tile,
                        StandardCopyOption.ATOMIC_MOVE,
                        StandardCopyOption.REPLACE_EXISTING);
            } catch (AtomicMoveNotSupportedException exception) {
                Files.move(temporaryTile, tile, StandardCopyOption.REPLACE_EXISTING);
            }
        } finally {
            Files.deleteIfExists(temporaryTile);
        }
    }

    private String tileName(int latitude, int longitude) {
        String latitudePart = (latitude >= 0 ? "N" : "S") + String.format("%02d", Math.abs(latitude));
        String longitudePart = (longitude >= 0 ? "E" : "W") + String.format("%03d", Math.abs(longitude));
        return latitudePart + longitudePart + ".hgt";
    }

    private record ProfileKey(RfCoordinate from, RfCoordinate to) {
    }
}
