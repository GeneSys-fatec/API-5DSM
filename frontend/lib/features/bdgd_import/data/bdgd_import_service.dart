import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_config.dart';
import '../models/bdgd_base.dart';

class BdgdImportService {
  Future<Map<String, dynamic>> upload({
    required String fileName,
    required Stream<List<int>>? fileStream,
    required int fileSize,
    String? filePath,
    required String distribuidora,
    required String regiao,
    required String data,
  }) async {
    final prefs = await SharedPreferences.getInstance(); 
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw BdgdUploadException('Sessão expirada. Faça login novamente.');
    }

    print('2. Montando o Request Multipart HTTP...');
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('${ApiConfig.baseUrl}/api/bdgd'),
          )
          ..headers['Authorization'] = 'Bearer $token'
          ..fields['distribuidora'] = distribuidora
          ..fields['regiao'] = regiao
          ..fields['data'] = data;

    if (fileStream != null) {
      print('3. Adicionando Stream ao Request (Tamanho: $fileSize bytes)');
      request.files.add(
        http.MultipartFile(
          'file',
          fileStream,
          fileSize,
          filename: fileName,
        ),
      );
    } else if (filePath != null && filePath.isNotEmpty) {
      print('3. Adicionando ficheiro por caminho: $filePath');
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath, filename: fileName),
      );
    } else {
      throw BdgdUploadException('Nenhum dado de ficheiro ou caminho foi fornecido.');
    }

    print('4. Chamando request.send() ... (Se travar aqui, o navegador não suporta este tamanho de ficheiro via Dart http)');
    final streamedResponse = await request.send();
    
    print('5. Resposta recebida! Lendo corpo... Status Code: ${streamedResponse.statusCode}');
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 202 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    var message = 'Erro HTTP ${response.statusCode}';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['error'] as String? ?? message;
    } catch (_) {
      message += ' - ${response.body.isNotEmpty ? response.body : "Sem resposta do servidor"}';
    }
    
    throw BdgdUploadException(message);
  }

  Future<List<BdgdBase>> fetchBases() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw BdgdUploadException('Sessão expirada. Faça login novamente.');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/bdgd/bases'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((item) => BdgdBase.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    var message = 'Não foi possível carregar as bases de dados.';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['error'] as String? ?? message;
    } catch (_) {}
    throw BdgdUploadException(message);
  }
}

class BdgdUploadException implements Exception {
  final String message;
  const BdgdUploadException(this.message);
}