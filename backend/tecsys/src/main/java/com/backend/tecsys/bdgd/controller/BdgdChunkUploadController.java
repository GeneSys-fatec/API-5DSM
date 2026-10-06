package com.backend.tecsys.bdgd.controller;

import com.backend.tecsys.bdgd.model.BdgdImportResponse;
import com.backend.tecsys.bdgd.service.BdgdChunkUploadService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.util.Map;

/**
 * Endpoint de upload chunked para arquivos grandes (> 100 MB).
 *
 * <p>Protocolo:
 * <ol>
 *   <li>POST /api/bdgd/upload/init  → obtém uploadId</li>
 *   <li>POST /api/bdgd/upload/chunk → envia um chunk por vez com header Content-Range</li>
 *   <li>POST /api/bdgd/upload/finalize → finaliza, dispara ETL</li>
 * </ol>
 */
@RestController
@RequestMapping("/api/bdgd/upload")
@RequiredArgsConstructor
public class BdgdChunkUploadController {

    private final BdgdChunkUploadService chunkService;

    /** Inicializa uma sessão de upload e retorna o uploadId. */
    @PostMapping("/init")
    @ResponseStatus(HttpStatus.OK)
    public Map<String, String> initUpload(
            @RequestParam("fileName") String fileName,
            @RequestParam("fileSize") long fileSize,
            @RequestParam("distribuidora") String distribuidora,
            @RequestParam("regiao") String regiao,
            @RequestParam("data") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate data) {

        String uploadId = chunkService.initSession(fileName, fileSize, distribuidora, regiao, data);
        return Map.of("uploadId", uploadId);
    }

    /**
     * Recebe um chunk do arquivo.
     *
     * <p>Header obrigatório: {@code Content-Range: bytes start-end/total}
     */
    @PostMapping(path = "/chunk", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.OK)
    public Map<String, Object> uploadChunk(
            @RequestParam("uploadId") String uploadId,
            @RequestParam("chunkIndex") int chunkIndex,
            @RequestParam("file") MultipartFile chunk) {

        long bytesReceived = chunkService.receiveChunk(uploadId, chunkIndex, chunk);
        return Map.of("uploadId", uploadId, "chunkIndex", chunkIndex, "bytesReceived", bytesReceived);
    }

    /** Finaliza o upload: remonta o arquivo e dispara o ETL. */
    @PostMapping("/finalize")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public BdgdImportResponse finalizeUpload(@RequestParam("uploadId") String uploadId) {
        return chunkService.finalizeAndDispatch(uploadId);
    }
}
