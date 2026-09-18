package com.backend.tecsys.infrastructure.provider;

import com.backend.tecsys.domain.model.RfCoordinate;
import com.backend.tecsys.domain.rf.TerrainProfile;
import com.backend.tecsys.domain.rf.TerrainProfileProvider;
import org.springframework.stereotype.Component;

@Component
public class EmptyTerrainProfileProvider implements TerrainProfileProvider {

    @Override
    public TerrainProfile getProfile(RfCoordinate from, RfCoordinate to) {
        return null;
    }
}
