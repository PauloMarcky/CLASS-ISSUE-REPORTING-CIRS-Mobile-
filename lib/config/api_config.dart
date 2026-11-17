import 'package:flutter/foundation.dart';

/// Where the Node.js API lives. Set at build time, never hard-coded secrets.
///
///   flutter run -d chrome --dart-define-from-file=dart_defines.example.json
///
/// Use separate build values for Web and Android. Android Emulators reach the
/// Windows host through 10.0.2.2, while Flutter Web reaches it through localhost.
class ApiConfig {
  ApiConfig._();

  static final String baseUrl = _resolveBaseUrl();

  static const Duration timeout = Duration(seconds: 10);

  static String _resolveBaseUrl() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const configuredAndroidUrl =
          String.fromEnvironment('API_ANDROID_BASE_URL');
      if (configuredAndroidUrl.isNotEmpty) return configuredAndroidUrl;
      return 'http://10.0.2.2:3000';
    }

    const configuredWebUrl = String.fromEnvironment('API_WEB_BASE_URL');
    if (configuredWebUrl.isNotEmpty) return configuredWebUrl;

    const legacyConfiguredUrl = String.fromEnvironment('API_BASE_URL');
    if (legacyConfiguredUrl.isNotEmpty) return legacyConfiguredUrl;
    return 'http://localhost:3000';
  }
}
