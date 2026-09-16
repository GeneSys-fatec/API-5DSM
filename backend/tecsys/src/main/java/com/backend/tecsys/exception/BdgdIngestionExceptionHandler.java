package com.backend.tecsys.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class BdgdIngestionExceptionHandler {
    @ExceptionHandler(InvalidBdgdUploadException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ApiErrorResponse invalid(InvalidBdgdUploadException exception) {
        return new ApiErrorResponse("INVALID_UPLOAD", exception.getMessage());
    }

    @ExceptionHandler(BdgdImportNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public ApiErrorResponse notFound(BdgdImportNotFoundException exception) {
        return new ApiErrorResponse("IMPORT_NOT_FOUND", exception.getMessage());
    }
}