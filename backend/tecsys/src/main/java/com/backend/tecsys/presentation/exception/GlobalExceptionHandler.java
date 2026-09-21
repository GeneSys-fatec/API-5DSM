package com.backend.tecsys.presentation.exception;

import com.backend.tecsys.application.service.AuthService;
import com.backend.tecsys.domain.exception.InvalidGatewayCandidateException;
import com.backend.tecsys.domain.exception.InvalidSimulationParameterException;
import com.backend.tecsys.domain.exception.PropagationCalculationException;
import com.backend.tecsys.domain.exception.ScenarioPersistenceException;
import com.backend.tecsys.domain.exception.UnavailableTerrainDataException;
import com.backend.tecsys.domain.exception.UnsupportedPropagationModelException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidationException(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error ->
                errors.put(error.getField(), error.getDefaultMessage())
        );

        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(Map.of(
                        "error", "Erro de validação nos campos informados.",
                        "status", 400,
                        "fields", errors,
                        "timestamp", LocalDateTime.now().toString()
                ));
    }

    @ExceptionHandler(AuthService.AuthenticationException.class)
    public ResponseEntity<Map<String, Object>> handleAuthenticationException(
            AuthService.AuthenticationException ex) {
        return ResponseEntity
                .status(HttpStatus.UNAUTHORIZED)
                .body(Map.of(
                        "error", ex.getMessage(),
                        "status", 401,
                        "timestamp", LocalDateTime.now().toString()
                ));
    }

    @ExceptionHandler(InvalidSimulationParameterException.class)
    public ResponseEntity<Map<String, Object>> handleInvalidSimulationParameter(
            InvalidSimulationParameterException ex) {
        return buildErrorResponse(ex.getMessage(), HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(UnsupportedPropagationModelException.class)
    public ResponseEntity<Map<String, Object>> handleUnsupportedPropagationModel(
            UnsupportedPropagationModelException ex) {
        return buildErrorResponse(ex.getMessage(), HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(InvalidGatewayCandidateException.class)
    public ResponseEntity<Map<String, Object>> handleInvalidGatewayCandidate(
            InvalidGatewayCandidateException ex) {
        return buildErrorResponse(ex.getMessage(), HttpStatus.BAD_REQUEST);
    }

    @ExceptionHandler(UnavailableTerrainDataException.class)
    public ResponseEntity<Map<String, Object>> handleUnavailableTerrainData(
            UnavailableTerrainDataException ex) {
        return buildErrorResponse(ex.getMessage(), HttpStatus.UNPROCESSABLE_CONTENT);
    }

    @ExceptionHandler(PropagationCalculationException.class)
    public ResponseEntity<Map<String, Object>> handlePropagationCalculation(
            PropagationCalculationException ex) {
        return buildErrorResponse(ex.getMessage(), HttpStatus.UNPROCESSABLE_CONTENT);
    }

    @ExceptionHandler(ScenarioPersistenceException.class)
    public ResponseEntity<Map<String, Object>> handleScenarioPersistence(
            ScenarioPersistenceException ex) {
        return buildErrorResponse(ex.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleGenericException(Exception ex) {
        return buildErrorResponse("Erro interno do servidor.", HttpStatus.INTERNAL_SERVER_ERROR);
    }

    private ResponseEntity<Map<String, Object>> buildErrorResponse(String message, HttpStatus status) {
        return ResponseEntity
                .status(status)
                .body(Map.of(
                        "error", message,
                        "status", status.value(),
                        "timestamp", LocalDateTime.now().toString()
                ));
    }
}

