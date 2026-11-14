abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://lexi-backend-z0zy.onrender.com/api',
  );

  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration aiRequestTimeout = Duration(seconds: 60);
}
