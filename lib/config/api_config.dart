/// Where the Node.js API lives. Set at build time, never hard-coded secrets.
///
///   flutter run -d chrome --dart-define-from-file=dart_defines.json
///
/// (copy dart_defines.example.json to dart_defines.json first).
/// Android emulator note: use http://10.0.2.2:3000 instead of localhost.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const Duration timeout = Duration(seconds: 10);
}
