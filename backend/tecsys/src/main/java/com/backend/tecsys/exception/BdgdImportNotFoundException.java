package com.backend.tecsys.exception;

public class BdgdImportNotFoundException extends RuntimeException {
    public BdgdImportNotFoundException() {
        super("Importacao nao encontrada");
    }
}