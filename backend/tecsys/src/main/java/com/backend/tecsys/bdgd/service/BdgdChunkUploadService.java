package com.backend.tecsys.bdgd.service;

import com.backend.tecsys.bdgd.config.BdgdIngestionProperties;
import com.backend.tecsys.bdgd.exception.InvalidBdgdUploadException;
import com.backend.tecsys.bdgd.model.BdgdImportRecord;
import com.backend.tecsys.bdgd.model.BdgdImportResponse;
import com.backend.tecsys.bdgd.model.BdgdImportStatus;
import com.backend.tecsys.bdgd.repository.BdgdImportRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.OutputStream;
import java.io.RandomAccessFile;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Serviço de upload em chunks para arquivos de múltiplos GB.
 *
 * <p>Fluxo:
 * <ol>
 *   <li>{@link #initSession} — cria arquivo temporário pré-alocado e registra metadados</li>
 *   <li>{@link #receiveChunk} — grava chunk na posição correta via RandomAccessFile</li>
 *   <li>{@link #finalizeAndDispatch} — verifica integridade, move para destino, dispara ETL</li>
 * </ol>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BdgdChunkUploadService {

    /** Metadados de uma sessão de upload ativa. */
    private record UploadSession(
            String uploadId,
            String fileName,
            long totalSize,
            String distribuidora,
            String regiao,
            LocalDate data,
            Path tempFile,
            String key,
            Set<Integer> receivedChunks
    ) {}

    private final Map<String, UploadSession> sessions = new ConcurrentHashMap<>();

    private final BdgdIngestionProperties properties;
    private final BdgdImportRepository repository;
    private final BdgdEtlDispatcher dispatcher;

    /**
     * Inicializa uma sessão de upload.
     *
     * @return uploadId que identifica esta sessão
     */
    public String initSession(String fileName, long totalSize, String distribuidora, String regiao, LocalDate data) {
        if (distribuidora == null || distribuidora.isBlank() || regiao == null || regiao.isBlank() || data == null) {
            throw new InvalidBdgdUploadException("Distribuidora, regiao e data sao obrigatorios");
        }
        if (totalSize <= 0 || totalSize > properties.getMaxUploadBytes()) {
            throw new InvalidBdgdUploadException(
                    "Tamanho inválido: " + totalSize + " bytes (máx: " + properties.getMaxUploadBytes() + ")");
        }

        String safeName = fileName.replaceAll("[^a-zA-Z0-9._-]", "_");
        LocalDate referenceDate = BdgdReferenceDateParser.parseOrDefault(safeName, data);
        String uploadId = UUID.randomUUID().toString();
        String key = String.format("%s/%s/%s/%s-%s", properties.getKeyPrefix(), distribuidora, data, uploadId, safeName);

        try {
            Path tempDir = Path.of(properties.getLocalDirectory(), "_chunks").toAbsolutePath().normalize();
            Files.createDirectories(tempDir);
            Path tempFile = tempDir.resolve(uploadId + ".tmp");

            // Pré-alocar o arquivo com o tamanho total para gravação aleatória eficiente
            try (RandomAccessFile raf = new RandomAccessFile(tempFile.toFile(), "rw")) {
                raf.setLength(totalSize);
            }

                sessions.put(uploadId, new UploadSession(
                    uploadId, safeName, totalSize, distribuidora, regiao, referenceDate, tempFile, key,
                    ConcurrentHashMap.newKeySet()));
            log.info("Sessão de upload iniciada: {} | arquivo={} | tamanho={} bytes", uploadId, safeName, totalSize);
            return uploadId;

        } catch (IOException e) {
            throw new IllegalStateException("Falha ao inicializar sessão de upload: " + e.getMessage(), e);
        }
    }

    /**
     * Recebe um chunk e o escreve na posição correta no arquivo temporário.
     *
     * @param uploadId   ID da sessão
     * @param chunkIndex índice sequencial do chunk (0-based)
     * @param chunk      dados do chunk
     * @return total de bytes gravados neste chunk
     */
    public long receiveChunk(String uploadId, int chunkIndex, MultipartFile chunk) {
        UploadSession session = getSession(uploadId);

        try {
            byte[] data = chunk.getBytes();
            long chunkSize = properties.getChunkSize();
            long offset = (long) chunkIndex * chunkSize;
            long expectedSize = Math.min(chunkSize, session.totalSize() - offset);

            if (chunkIndex < 0 || offset < 0 || offset >= session.totalSize() || data.length != expectedSize) {
                throw new InvalidBdgdUploadException(
                        "Chunk inválido: índice=" + chunkIndex + ", bytes=" + data.length);
            }

            try (RandomAccessFile raf = new RandomAccessFile(session.tempFile().toFile(), "rw")) {
                raf.seek(offset);
                raf.write(data);
            }
            session.receivedChunks().add(chunkIndex);

            log.debug("Chunk {} recebido para {}: {} bytes no offset {}", chunkIndex, uploadId, data.length, offset);
            return data.length;

        } catch (IOException e) {
            throw new IllegalStateException("Falha ao gravar chunk " + chunkIndex + ": " + e.getMessage(), e);
        }
    }

    /**
     * Finaliza o upload: move o arquivo para o destino definitivo e dispara o ETL.
     */
    public BdgdImportResponse finalizeAndDispatch(String uploadId) {
        UploadSession session = getSession(uploadId);

        try {
            // Verifica tamanho real
            long actualSize = Files.size(session.tempFile());
            if (actualSize != session.totalSize()) {
                throw new InvalidBdgdUploadException(
                        String.format("Arquivo incompleto: esperado %d bytes, recebido %d bytes",
                                session.totalSize(), actualSize));
            }
            long expectedChunks = (session.totalSize() + properties.getChunkSize() - 1)
                    / properties.getChunkSize();
            if (session.receivedChunks().size() != expectedChunks
                    || session.receivedChunks().stream().anyMatch(index -> index < 0 || index >= expectedChunks)) {
                throw new InvalidBdgdUploadException("Arquivo incompleto: faltam chunks");
            }

            // Mover para destino final
            Path destination = Path.of(properties.getLocalDirectory(), session.key()).toAbsolutePath().normalize();
            Files.createDirectories(destination.getParent());
            Files.move(session.tempFile(), destination, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            log.info("Upload finalizado: {} → {}", uploadId, destination);

            // Criar registro e disparar ETL
            UUID id = UUID.randomUUID();
            BdgdImportRecord record = new BdgdImportRecord(
                    id,
                    session.distribuidora(),
                    session.regiao(),
                    session.data(),
                    session.fileName(),
                    session.key(),
                    BdgdImportStatus.PROCESSANDO,
                    null,
                    Instant.now()
            );
            repository.create(record);
            dispatcher.dispatch(id);

            sessions.remove(uploadId);
            return BdgdImportResponse.from(record);

        } catch (IOException e) {
            throw new IllegalStateException("Falha ao finalizar upload: " + e.getMessage(), e);
        }
    }

    private UploadSession getSession(String uploadId) {
        UploadSession session = sessions.get(uploadId);
        if (session == null) {
            throw new InvalidBdgdUploadException("Sessão de upload não encontrada: " + uploadId);
        }
        return session;
    }
}
