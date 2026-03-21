import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  // Override with --dart-define=API_BASE_URL=http://<host>:8080
  static const String _definedBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) return _definedBaseUrl;

    if (kIsWeb) return 'http://localhost:8080';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator default host mapping
        return 'http://10.0.2.2:8080';
      default:
        return 'http://localhost:8080';
    }
  }
}
