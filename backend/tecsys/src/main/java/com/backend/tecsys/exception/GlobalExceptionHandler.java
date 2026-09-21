package com.backend.tecsys.exception;

import com.backend.tecsys.auth.service.AuthService;
import com.backend.tecsys.bdgd.exception.InvalidBdgdUploadException;
import com.backend.tecsys.scenario.exception.InvalidGatewayCandidateException;
import com.backend.tecsys.scenario.exception.InvalidSimulationParameterException;
import com.backend.tecsys.radio.exception.PropagationCalculationException;
import com.backend.tecsys.scenario.exception.ScenarioPersistenceException;
import com.backend.tecsys.radio.exception.UnavailableTerrainDataException;
import com.backend.tecsys.radio.exception.UnsupportedPropagationModelException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

        @ExceptionHandler(MethodArgumentNotValidException.class)
        public ResponseEntity<Map<String, Object>> handleValidationException(MethodArgumentNotValidException ex) {
                Map<String, String> errors = new HashMap<>();
                ex.getBindingResult().getFieldErrors().forEach(error ->
                                errors.put(error.getField(), error.getDefaultMessage()));

                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                                "error", "Erro de validação nos campos informados.",
                                "status", 400,
                                "fields", errors,
                                "timestamp", LocalDateTime.now().toString()));
        }

        @ExceptionHandler(AuthService.AuthenticationException.class)
        public ResponseEntity<Map<String, Object>> handleAuthenticationException(AuthService.AuthenticationException ex) {
                return buildErrorResponse(ex.getMessage(), HttpStatus.UNAUTHORIZED);
        }

        @ExceptionHandler(InvalidBdgdUploadException.class)
        public ResponseEntity<Map<String, Object>> handleInvalidBdgdUpload(InvalidBdgdUploadException ex) {
                return buildErrorResponse(ex.getMessage(), HttpStatus.BAD_REQUEST, "INVALID_UPLOAD");
        }

        @ExceptionHandler({
                        InvalidSimulationParameterException.class,
                        UnsupportedPropagationModelException.class,
                        InvalidGatewayCandidateException.class
        })
        public ResponseEntity<Map<String, Object>> handleInvalidSimulation(Exception ex) {
                return buildErrorResponse(ex.getMessage(), HttpStatus.BAD_REQUEST);
        }

        @ExceptionHandler({UnavailableTerrainDataException.class, PropagationCalculationException.class})
        public ResponseEntity<Map<String, Object>> handleCalculation(Exception ex) {
                return buildErrorResponse(ex.getMessage(), HttpStatus.UNPROCESSABLE_CONTENT);
        }

        @ExceptionHandler(ScenarioPersistenceException.class)
        public ResponseEntity<Map<String, Object>> handleScenarioPersistence(ScenarioPersistenceException ex) {
                return buildErrorResponse(ex.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }

        @ExceptionHandler(Exception.class)
        public ResponseEntity<Map<String, Object>> handleGenericException(Exception ex) {
                log.error("Erro interno ao processar requisicao: {}", ex.getMessage(), ex);
                return buildErrorResponse("Erro interno do servidor.", HttpStatus.INTERNAL_SERVER_ERROR);
        }

        private ResponseEntity<Map<String, Object>> buildErrorResponse(String message, HttpStatus status) {
                return buildErrorResponse(message, status, null);
        }

        private ResponseEntity<Map<String, Object>> buildErrorResponse(
                        String message, HttpStatus status, String code) {
                Map<String, Object> body = new HashMap<>();
                body.put("error", message);
                body.put("status", status.value());
                body.put("timestamp", LocalDateTime.now().toString());
                if (code != null) {
                        body.put("code", code);
                }
                return ResponseEntity.status(status).body(body);
        }
}

