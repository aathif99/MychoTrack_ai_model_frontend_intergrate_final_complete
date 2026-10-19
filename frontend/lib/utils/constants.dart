import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  /// =========================================================================
  /// AWS EC2 BACKEND CONFIGURATION
  /// =========================================================================
  /// Replace this with your AWS EC2 Public IPv4 or Domain once launched:
  /// Example: 'http://3.85.123.45:3000'
  static const String awsServerUrl = 'http://3.111.55.81:3000';

  /// Azure backend URL (fallback)
  static const String liveAzureUrl = 'https://skindisease-api-dell-cudnhqa7dud6hbb0.southindia-01.azurewebsites.net';

  /// Set to true to route all mobile app requests to your AWS EC2 backend
  static const bool useAwsCloud = true;

  static String get serverUrl {
    if (useAwsCloud && !awsServerUrl.contains('YOUR_AWS_EC2_PUBLIC_IP')) {
      return awsServerUrl;
    }
    return liveAzureUrl;
  }

  static String get baseUrl {
    return '$serverUrl/api';
  }
}

