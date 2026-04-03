import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  // Override with --dart-define=API_BASE_URL=http://<host>:8080
  static const String _definedBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  // Set true on Android emulator to use 10.0.2.2 instead of localhost.
  static const bool _useAndroidEmulatorHost = bool.fromEnvironment(
    'API_USE_ANDROID_EMULATOR_HOST',
    defaultValue: false,
  );

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) return _definedBaseUrl;

    if (kIsWeb) return 'http://localhost:8080';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Physical device + adb reverse workflow uses localhost.
        // Use --dart-define=API_USE_ANDROID_EMULATOR_HOST=true on emulator.
        return _useAndroidEmulatorHost
            ? 'http://10.0.2.2:8080'
            : 'http://localhost:8080';
      default:
        return 'http://localhost:8080';
    }
  }
}
