package com.backend.tecsys.radio.service;

import com.backend.tecsys.radio.model.RfCoordinate;

public final class GeoDistanceCalculator {

    private static final double EARTH_RADIUS_M = 6371000.0;

    private GeoDistanceCalculator() {
    }

    public static double distanceMeters(RfCoordinate from, RfCoordinate to) {
        double lat1 = Math.toRadians(from.latitude());
        double lat2 = Math.toRadians(to.latitude());
        double deltaLat = Math.toRadians(to.latitude() - from.latitude());
        double deltaLon = Math.toRadians(to.longitude() - from.longitude());

        double haversine = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2)
                + Math.cos(lat1) * Math.cos(lat2)
                * Math.sin(deltaLon / 2) * Math.sin(deltaLon / 2);

        double angularDistance = 2 * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine));
        return EARTH_RADIUS_M * angularDistance;
    }
}
