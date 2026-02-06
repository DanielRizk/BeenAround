import 'package:flutter/foundation.dart';

class BackendConfig {
  /// Set this to your PC IP when testing on a real phone.
  /// Example: 'http://192.168.178.25:8080'
  static const String physicalAndroidBaseUrl = 'http://192.168.0.103:8080';

  static String baseUrl() {
    if (kIsWeb) return 'http://localhost:8080';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      // Emulator: 10.0.2.2
      // Real phone: set physicalAndroidBaseUrl
        return physicalAndroidBaseUrl; // <-- change to 10.0.2.2 if emulator
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:8080';
      default:
        return 'http://localhost:8080';
    }
  }
}
