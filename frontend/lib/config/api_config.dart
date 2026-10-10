class ApiConfig {
  ApiConfig._();

  static const String productionBaseUrl =
      'https://car-ai-backend-7gpb.onrender.com';

  /// Override at build/run time with:
  /// --dart-define=API_BASE_URL=http://10.0.2.2:3000
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionBaseUrl,
  );

  static String get baseUrl => _configuredBaseUrl.endsWith('/')
      ? _configuredBaseUrl.substring(0, _configuredBaseUrl.length - 1)
      : _configuredBaseUrl;

  static String get apiBaseUrl => '$baseUrl/api';

  static Uri apiUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$apiBaseUrl$normalizedPath');
  }

  static Uri rootUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }
}
