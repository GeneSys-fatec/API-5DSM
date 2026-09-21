package com.backend.tecsys.bdgd.exception;

public class BdgdImportNotFoundException extends RuntimeException {
    public BdgdImportNotFoundException() {
        super("Importacao nao encontrada");
    }
}
