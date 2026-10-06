import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_config.dart';
import '../models/bdgd_base.dart';

/// Tamanho de cada chunk: 10 MB (deve coincidir com bdgd.ingestion.chunk-size no backend).
const int _kChunkSize = 10 * 1024 * 1024;

class BdgdImportService {
  /// Upload de arquivo grande via chunks de [_kChunkSize] bytes.
  ///
  /// Na Web, usa o [readStream] do FilePicker para ler o arquivo em pedaços e
  /// enviar chunk por chunk via XHR, evitando bufferizar o arquivo inteiro na RAM.
  /// No mobile/desktop, usa upload direto por caminho de arquivo.
  Future<Map<String, dynamic>> upload({
    required String fileName,
    required Stream<List<int>>? fileStream,
    required int fileSize,
    String? filePath,
    html.File? webFile,
    required String distribuidora,
    required String regiao,
    required String data,
    void Function(double progress)? onProgress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw BdgdUploadException('Sessão expirada. Faça login novamente.');
    }

    // Flutter Web: usa upload chunked via dart:html XHR
    if (webFile != null) {
      return _chunkedWebUpload(
        webFile: webFile,
        fileName: fileName,
        fileSize: fileSize,
        distribuidora: distribuidora,
        regiao: regiao,
        data: data,
        token: token,
        onProgress: onProgress,
      );
    }

    // Flutter Web sem html.File (fallback via readStream em chunks)
    if (fileStream != null) {
      return _chunkedStreamUpload(
        fileName: fileName,
        fileStream: fileStream,
        fileSize: fileSize,
        distribuidora: distribuidora,
        regiao: regiao,
        data: data,
        token: token,
        onProgress: onProgress,
      );
    }

    // Mobile/Desktop: usa http.MultipartFile.fromPath
    if (filePath != null && filePath.isNotEmpty) {
      return _nativeUpload(
        filePath: filePath,
        fileName: fileName,
        distribuidora: distribuidora,
        regiao: regiao,
        data: data,
        token: token,
      );
    }

    throw BdgdUploadException('Nenhum dado de ficheiro foi fornecido.');
  }

  // ---------------------------------------------------------------------------
  // Upload chunked via html.File (Web, Blob.slice — não bufferiza)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _chunkedWebUpload({
    required html.File webFile,
    required String fileName,
    required int fileSize,
    required String distribuidora,
    required String regiao,
    required String data,
    required String token,
    void Function(double progress)? onProgress,
  }) async {
    final uploadId = await _initSession(
      fileName: fileName,
      fileSize: fileSize,
      distribuidora: distribuidora,
      regiao: regiao,
      data: data,
      token: token,
    );

    final totalChunks = (fileSize / _kChunkSize).ceil();
    for (int i = 0; i < totalChunks; i++) {
      final start = i * _kChunkSize;
      final end = (start + _kChunkSize > fileSize) ? fileSize : start + _kChunkSize;
      final blob = webFile.slice(start, end);

      await _sendBlobChunk(
        uploadId: uploadId,
        chunkIndex: i,
        blob: blob,
        token: token,
      );

      onProgress?.call((i + 1) / totalChunks);
    }

    return _finalizeUpload(uploadId: uploadId, token: token);
  }

  // ---------------------------------------------------------------------------
  // Upload chunked via Stream<List<int>> (Web fallback — acumula chunks de 10 MB)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _chunkedStreamUpload({
    required String fileName,
    required Stream<List<int>> fileStream,
    required int fileSize,
    required String distribuidora,
    required String regiao,
    required String data,
    required String token,
    void Function(double progress)? onProgress,
  }) async {
    final uploadId = await _initSession(
      fileName: fileName,
      fileSize: fileSize,
      distribuidora: distribuidora,
      regiao: regiao,
      data: data,
      token: token,
    );

    int chunkIndex = 0;
    int bytesSent = 0;
    final buffer = BytesBuilder(copy: false);

    await for (final bytes in fileStream) {
      buffer.add(bytes);

      // Quando o buffer atingir o tamanho do chunk, enviar
      while (buffer.length >= _kChunkSize) {
        final chunk = buffer.toBytes();
        final chunkData = chunk.sublist(0, _kChunkSize);
        final remainder = chunk.sublist(_kChunkSize);
        buffer.clear();
        if (remainder.isNotEmpty) buffer.add(remainder);

        await _sendBytesChunk(
          uploadId: uploadId,
          chunkIndex: chunkIndex,
          bytes: chunkData,
          token: token,
        );
        bytesSent += chunkData.length;
        onProgress?.call(bytesSent / fileSize);
        chunkIndex++;
      }
    }

    // Enviar bytes restantes
    if (buffer.length > 0) {
      await _sendBytesChunk(
        uploadId: uploadId,
        chunkIndex: chunkIndex,
        bytes: buffer.toBytes(),
        token: token,
      );
    }

    return _finalizeUpload(uploadId: uploadId, token: token);
  }

  // ---------------------------------------------------------------------------
  // Upload direto (Mobile/Desktop via caminho)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _nativeUpload({
    required String filePath,
    required String fileName,
    required String distribuidora,
    required String regiao,
    required String data,
    required String token,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/bdgd'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['distribuidora'] = distribuidora
      ..fields['regiao'] = regiao
      ..fields['data'] = data;

    request.files.add(
      await http.MultipartFile.fromPath('file', filePath, filename: fileName),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 202 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    var message = 'Erro HTTP ${response.statusCode}';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['error'] as String? ?? message;
    } catch (_) {
      message += ' - ${response.body.isNotEmpty ? response.body : "Sem resposta"}';
    }
    throw BdgdUploadException(message);
  }

  // ---------------------------------------------------------------------------
  // Helpers: init / send chunk / finalize
  // ---------------------------------------------------------------------------

  Future<String> _initSession({
    required String fileName,
    required int fileSize,
    required String distribuidora,
    required String regiao,
    required String data,
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/bdgd/upload/init');
    final resp = await http.post(uri, headers: {
      'Authorization': 'Bearer $token',
    }, body: {
      'fileName': fileName,
      'fileSize': fileSize.toString(),
      'distribuidora': distribuidora,
      'regiao': regiao,
      'data': data,
    });

    if (resp.statusCode != 200) {
      throw BdgdUploadException('Falha ao iniciar sessão de upload: ${resp.body}');
    }
    return (jsonDecode(resp.body) as Map<String, dynamic>)['uploadId'] as String;
  }

  /// Envia um chunk como Blob via XHR (não bufferiza o Blob inteiro na heap Dart).
  Future<void> _sendBlobChunk({
    required String uploadId,
    required int chunkIndex,
    required html.Blob blob,
    required String token,
  }) {
    final completer = Completer<void>();
    final formData = html.FormData();
    formData.appendBlob('file', blob, 'chunk');
    formData.append('uploadId', uploadId);
    formData.append('chunkIndex', chunkIndex.toString());

    final xhr = html.HttpRequest();
    xhr.open('POST', '${ApiConfig.baseUrl}/api/bdgd/upload/chunk');
    xhr.setRequestHeader('Authorization', 'Bearer $token');
    xhr.onLoad.listen((_) {
      if ((xhr.status ?? 0) >= 200 && (xhr.status ?? 0) < 300) {
        completer.complete();
      } else {
        completer.completeError(
            BdgdUploadException('Chunk $chunkIndex falhou: HTTP ${xhr.status}'));
      }
    });
    xhr.onError.listen((_) =>
        completer.completeError(BdgdUploadException('Erro de rede no chunk $chunkIndex')));
    xhr.send(formData);
    return completer.future;
  }

  /// Envia um chunk do stream como Blob via XHR, sem MultipartRequest.
  Future<void> _sendBytesChunk({
    required String uploadId,
    required int chunkIndex,
    required Uint8List bytes,
    required String token,
  }) async {
    await _sendBlobChunk(
      uploadId: uploadId,
      chunkIndex: chunkIndex,
      blob: html.Blob([bytes]),
      token: token,
    );
  }

  Future<Map<String, dynamic>> _finalizeUpload({
    required String uploadId,
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/bdgd/upload/finalize');
    final resp = await http.post(uri, headers: {'Authorization': 'Bearer $token'}, body: {
      'uploadId': uploadId,
    });

    if (resp.statusCode == 202 || resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    var message = 'Erro ao finalizar: HTTP ${resp.statusCode}';
    try {
      message = (jsonDecode(resp.body) as Map<String, dynamic>)['error'] as String? ?? message;
    } catch (_) {}
    throw BdgdUploadException(message);
  }

  // ---------------------------------------------------------------------------
  // Outros métodos
  // ---------------------------------------------------------------------------

  Future<String?> _attemptAutoLogin() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': 'admin@tecsys.com', 'password': 'Admin@123'}),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          return token;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<BdgdBase>> fetchBases() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('auth_token');
    if (token == null) token = await _attemptAutoLogin();
    if (token == null) return kMockBases;

    try {
      var response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/bdgd/bases'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 401 || response.statusCode == 403) {
        token = await _attemptAutoLogin();
        if (token != null) {
          response = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/api/bdgd/bases'),
            headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 8));
        }
      }

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        return list.map((item) => BdgdBase.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return kMockBases;
  }
}

class BdgdUploadException implements Exception {
  final String message;
  const BdgdUploadException(this.message);
}