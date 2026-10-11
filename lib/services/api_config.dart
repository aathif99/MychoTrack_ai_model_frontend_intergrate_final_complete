import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  /// =========================================================================
  /// AWS EC2 BACKEND CONFIGURATION
  /// =========================================================================
  /// Replace this with your AWS EC2 Public IPv4 or Domain Name once launched.
  /// Example: 'http://3.85.123.45:3000' or 'http://your-domain.com:3000'
  static const String awsServerUrl = 'http://13.211.149.114:3000';

  /// Set to true to connect the mobile app to AWS EC2 (for real users & APK builds)
  /// Set to false when developing locally with Android Studio emulator / localhost
  static const bool useAwsCloud = true;

  /// Active Base URL for all API requests across the app
  static String get baseUrl {
    // When AWS Cloud is active and the IP has been provided, use AWS
    if (useAwsCloud && !awsServerUrl.contains('YOUR_AWS_EC2_PUBLIC_IP')) {
      return awsServerUrl;
    }

    // Local development fallback
    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android Studio emulator
        return 'http://10.0.2.2:3000';

      case TargetPlatform.iOS:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:3000';
    }
  }
}