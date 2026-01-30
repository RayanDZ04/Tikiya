class AppConfig {
  // For local web dev, API is typically reachable at localhost.
  // If you proxy via docker-compose, keep it consistent.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
