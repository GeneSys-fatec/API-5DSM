package com.backend.tecsys.radio.repository;import com.backend.tecsys.radio.model.TerrainProfile;


import com.backend.tecsys.radio.model.RfCoordinate;

public interface TerrainProfileProvider {

    TerrainProfile getProfile(RfCoordinate from, RfCoordinate to);
}
