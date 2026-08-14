class AppConfig {
  AppConfig._();

  /// API endpoint is injected at build time for production builds.
  ///
  /// Development remains local by default. For Play Store builds use:
  ///
  /// flutter build appbundle --release \
  ///   --dart-define=API_BASE_URL=https://api.example.com
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static String get normalizedApiBaseUrl {
    final value = apiBaseUrl.trim();
    if (value.isEmpty) {
      throw StateError('API_BASE_URL must not be empty.');
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
