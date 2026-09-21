package com.backend.tecsys.domain.exception;

public class PropagationCalculationException extends RuntimeException {
    public PropagationCalculationException(String message) {
        super(message);
    }

    public PropagationCalculationException(String message, Throwable cause) {
        super(message, cause);
    }
}
