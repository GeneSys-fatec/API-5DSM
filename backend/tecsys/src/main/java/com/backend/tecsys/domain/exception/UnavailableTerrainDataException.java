package com.backend.tecsys.domain.exception;

public class UnavailableTerrainDataException extends PropagationCalculationException {
    public UnavailableTerrainDataException(String message) {
        super(message);
    }
}
