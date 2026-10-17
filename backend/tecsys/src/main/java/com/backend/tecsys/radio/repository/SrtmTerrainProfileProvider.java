package com.backend.tecsys.radio.repository;

import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.radio.model.TerrainProfile;
import com.backend.tecsys.radio.service.GeoDistanceCalculator;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
@Profile("!mock")
public class SrtmTerrainProfileProvider implements TerrainProfileProvider {
    private static final int MAX_SAMPLES = 64;
    private final Path directory;
    private final Map<Path, short[]> tileCache = new ConcurrentHashMap<>();
    private final Map<Path, Integer> resolutionCache = new ConcurrentHashMap<>();

    public SrtmTerrainProfileProvider(
            @Value("${terrain.srtm-directory:}") String directory) {
        this.directory = directory == null || directory.isBlank() ? null : Path.of(directory);
    }

    @Override
    public TerrainProfile getProfile(RfCoordinate from, RfCoordinate to) {
        if (directory == null || !Files.isDirectory(directory)) {
            return TerrainProfile.empty();
        }

        double distance = GeoDistanceCalculator.distanceMeters(from, to);
        int sampleCount = Math.max(2, Math.min(MAX_SAMPLES, (int) Math.ceil(distance / 250.0) + 1));
        double spacing = distance / (sampleCount - 1);
        double[] elevations = new double[sampleCount];
        for (int index = 0; index < sampleCount; index++) {
            double fraction = index / (double) (sampleCount - 1);
            double latitude = from.latitude() + (to.latitude() - from.latitude()) * fraction;
            double longitude = from.longitude() + (to.longitude() - from.longitude()) * fraction;
            Double elevation = readElevation(latitude, longitude);
            if (elevation == null) {
                return TerrainProfile.empty();
            }
            elevations[index] = elevation;
        }
        return new TerrainProfile(elevations, spacing);
    }

    private Double readElevation(double latitude, double longitude) {
        int latitudeTile = (int) Math.floor(latitude);
        int longitudeTile = (int) Math.floor(longitude);
        Path tile = directory.resolve(tileName(latitudeTile, longitudeTile));
        try {
            short[] values = tileCache.computeIfAbsent(tile, this::loadTile);
            if (values == null) {
                return null;
            }
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
        try {
            byte[] bytes = Files.readAllBytes(tile);
            if (bytes.length < 2 || bytes.length % 2 != 0) {
                return null;
            }
            short[] values = new short[bytes.length / 2];
            ByteBuffer buffer = ByteBuffer.wrap(bytes).order(ByteOrder.BIG_ENDIAN);
            buffer.asShortBuffer().get(values);
            int resolution = (int) Math.sqrt(values.length) - 1;
            return resolution > 0 && (resolution + 1) * (resolution + 1) == values.length ? values : null;
        } catch (IOException exception) {
            return null;
        }
    }

    private String tileName(int latitude, int longitude) {
        String latitudePart = (latitude >= 0 ? "N" : "S") + String.format("%02d", Math.abs(latitude));
        String longitudePart = (longitude >= 0 ? "E" : "W") + String.format("%03d", Math.abs(longitude));
        return latitudePart + longitudePart + ".hgt";
    }
}
