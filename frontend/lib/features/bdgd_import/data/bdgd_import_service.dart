import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_config.dart';

class BdgdImportService {
  Future<Map<String, dynamic>> upload({
    required String fileName,
    required List<int> fileBytes,
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

    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('${ApiConfig.baseUrl}/api/bdgd'),
          )
          ..headers['Authorization'] = 'Bearer $token'
          ..fields['distribuidora'] = distribuidora
          ..fields['regiao'] = regiao
          ..fields['data'] = data;

    if (filePath != null && filePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath, filename: fileName),
      );
    } else {
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 202) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    var message = 'Não foi possível enviar o arquivo.';
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
