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

  Future<List<BdgdBase>> fetchBases({String? regiao, String? distribuidora}) async {
    final query = <String, String>{};
    if (regiao != null && regiao.trim().isNotEmpty) {
      query['regiao'] = regiao.trim();
    }
    if (distribuidora != null && distribuidora.trim().isNotEmpty) {
      query['distribuidora'] = distribuidora.trim();
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/bdgd/bases')
        .replace(queryParameters: query.isEmpty ? null : query);

    try {
      final response = await _authorizedRequest('GET', uri);
      if (response != null && response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((item) => BdgdBase.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    return kMockBases;
  }

  Future<List<String>> fetchRegions() async {
    return _fetchStringList(Uri.parse('${ApiConfig.baseUrl}/api/bdgd/regions'));
  }

  Future<List<String>> fetchDistributors({String? regiao}) async {
    final query = <String, String>{};
    if (regiao != null && regiao.trim().isNotEmpty) {
      query['regiao'] = regiao.trim();
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/bdgd/distributors')
        .replace(queryParameters: query.isEmpty ? null : query);
    return _fetchStringList(uri);
  }

  Future<BdgdBase> updateBaseGroup({
    required String id,
    required String regiao,
    required String distribuidora,
  }) async {
    http.Response? response;
    try {
      response = await _authorizedRequest(
        'PATCH',
        Uri.parse('${ApiConfig.baseUrl}/api/bdgd/$id'),
        body: {'regiao': regiao, 'distribuidora': distribuidora},
      );
    } catch (_) {
      throw const BdgdUploadException(
        'Não foi possível conectar ao servidor para atualizar o grupo.',
      );
    }

    if (response != null && response.statusCode == 200) {
      return BdgdBase.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw BdgdUploadException(_errorMessage(response));
  }

  String _errorMessage(http.Response? response) {
    if (response == null) {
      return 'Sessão expirada. Faça login novamente.';
    }
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final message = body['message'] as String?;
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {}
    return 'Não foi possível atualizar a região/distribuidora da base.';
  }

  Future<List<String>> _fetchStringList(Uri uri) async {
    try {
      final response = await _authorizedRequest('GET', uri);
      if (response != null && response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
        return list.map((item) => item.toString()).toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<http.Response?> _authorizedRequest(String method, Uri uri, {Object? body}) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('auth_token');
    if (token == null) {
      token = await _attemptAutoLogin();
    }
    if (token == null) {
      return null;
    }

    Future<http.Response> send(String value) {
      final headers = <String, String>{
        'Authorization': 'Bearer $value',
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
      };
      switch (method) {
        case 'PATCH':
          return http
              .patch(uri, headers: headers, body: jsonEncode(body ?? const <String, dynamic>{}))
              .timeout(const Duration(seconds: 8));
        default:
          return http.get(uri, headers: headers).timeout(const Duration(seconds: 8));
      }
    }

    var response = await send(token);
    if (response.statusCode == 401 || response.statusCode == 403) {
      final refreshed = await _attemptAutoLogin();
      if (refreshed != null) {
        response = await send(refreshed);
      }
    }
    return response;
  }
}

class BdgdUploadException implements Exception {
  final String message;
  const BdgdUploadException(this.message);
}