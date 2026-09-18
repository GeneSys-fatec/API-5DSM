package com.backend.tecsys.domain.rf;

import com.backend.tecsys.domain.model.RfCoordinate;

public interface TerrainProfileProvider {

    TerrainProfile getProfile(RfCoordinate from, RfCoordinate to);
}
