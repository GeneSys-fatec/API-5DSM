/// Configuração centralizada da API.
///
/// Quando o backend mudar de endereço (ex: deploy em produção),
/// a única mudança necessária no frontend é alterar [baseUrl] aqui.
class ApiConfig {
  ApiConfig._();

  /// URL base da API.
  ///
  /// - Android Emulator: use 'http://10.0.2.2:8080'
  /// - Web/Desktop/iOS Simulator: use 'http://localhost:8080'
  static const String baseUrl = 'http://localhost:8080';
}
