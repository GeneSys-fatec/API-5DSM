package com.backend.tecsys.radio.repository;

import com.backend.tecsys.radio.model.RfCoordinate;
import com.backend.tecsys.radio.model.TerrainProfile;
import org.springframework.stereotype.Component;
import org.springframework.context.annotation.Profile;

@Component
@Profile("mock")
public class EmptyTerrainProfileProvider implements TerrainProfileProvider {

    @Override
    public TerrainProfile getProfile(RfCoordinate from, RfCoordinate to) {
        return null;
    }
}
