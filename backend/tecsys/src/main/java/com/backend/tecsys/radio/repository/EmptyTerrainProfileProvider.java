package com.backend.tecsys.radio.repository;

import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.radio.model.TerrainProfile;
import org.springframework.stereotype.Component;

@Component
public class EmptyTerrainProfileProvider implements TerrainProfileProvider {

    @Override
    public TerrainProfile getProfile(RfCoordinate from, RfCoordinate to) {
        return null;
    }
}
