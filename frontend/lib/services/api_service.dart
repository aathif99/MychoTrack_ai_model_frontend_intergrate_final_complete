import 'dart:convert';
import 'package:flutter/material.dart' show MaterialPageRoute;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import '../utils/constants.dart';
import '../utils/navigator_key.dart';
import '../screens/welcome_screen.dart';
import '../models/prediction_result.dart';
import '../models/history_item.dart';

class ApiService {
  static const String tokenKey = 'jwt_token';
  static const String usernameKey = 'username';
  static const String emailKey = 'email';

  // Make it a singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> saveUserDetails(String username, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(usernameKey, username);
    await prefs.setString(emailKey, email);
  }

  Future<Map<String, String?>> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(usernameKey),
      'email': prefs.getString(emailKey),
    };
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(usernameKey);
    await prefs.remove(emailKey);
  }

  Future<bool> verifyToken() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return false;

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/auth/verify'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        await removeToken();
        return false;
      }
      return false;
    } catch (_) {
      // On connection errors, don't boot the user out so offline access is possible
      return true;
    }
  }

  void _handleUnauthorized() async {
    await removeToken();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
  }

  dynamic _parseJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  // --- Auth & Profile API ---

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = _parseJson(response.body);

      if (response.statusCode == 200 && data != null) {
        await saveToken(data['token']);
        final user = data['user'];
        if (user != null) {
          await saveUserDetails(user['username'], user['email']);
        }
        return {'success': true, 'message': data['message'], 'user': data['user']};
      } else {
        final msg = data != null ? (data['error'] ?? data['message'] ?? 'Login failed') : 'Server error (${response.statusCode})';
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      final data = _parseJson(response.body);

      if (response.statusCode == 201 && data != null) {
        return {'success': true, 'message': data['message']};
      } else {
        final msg = data != null ? (data['error'] ?? data['message'] ?? 'Registration failed') : 'Server error (${response.statusCode})';
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<void> logout() async {
    final token = await getToken();
    await removeToken();
    if (token != null) {
      http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/logout'),
        headers: {'Authorization': 'Bearer $token'},
      ).catchError((_) => http.Response('', 500));
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not authenticated'};

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/auth/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 401) {
        _handleUnauthorized();
        return {'success': false, 'message': 'Session expired'};
      }

      final data = _parseJson(response.body);
      if (response.statusCode == 200 && data != null && data['user'] != null) {
        final user = data['user'];
        if (user['username'] != null && user['email'] != null) {
          await saveUserDetails(user['username'], user['email']);
        }
        return {'success': true, 'user': user};
      } else {
        final msg = data != null ? (data['error'] ?? data['message'] ?? 'Failed to get profile') : 'Server error (${response.statusCode})';
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> uploadProfilePicture(String imagePath) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not authenticated'};

      var request = http.MultipartRequest('POST', Uri.parse('${AppConstants.baseUrl}/auth/profile-picture'));
      request.headers['Authorization'] = 'Bearer $token';

      final ext = imagePath.split('.').last.toLowerCase();
      final mediaType = ext == 'png' ? MediaType('image', 'png') : MediaType('image', 'jpeg');

      request.files.add(await http.MultipartFile.fromPath(
        'profile_picture',
        imagePath,
        contentType: mediaType,
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401) {
        _handleUnauthorized();
        return {'success': false, 'message': 'Session expired'};
      }

      final data = _parseJson(response.body);
      if (response.statusCode == 200 && data != null) {
        return {
          'success': true,
          'message': data['message'] ?? 'Profile picture updated successfully',
          'profile_picture': data['profile_picture']
        };
      } else {
        final msg = data != null ? (data['error'] ?? data['message'] ?? 'Upload failed') : 'Server error (${response.statusCode})';
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Upload error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteProfilePicture() async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not authenticated'};

      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/auth/profile-picture'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 401) {
        _handleUnauthorized();
        return {'success': false, 'message': 'Session expired'};
      }

      final data = _parseJson(response.body);
      if (response.statusCode == 200 && data != null) {
        return {
          'success': true,
          'message': data['message'] ?? 'Profile picture removed successfully'
        };
      } else {
        final msg = data != null ? (data['error'] ?? data['message'] ?? 'Removal failed') : 'Server error (${response.statusCode})';
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = _parseJson(response.body);
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'message': data['message']};
      } else {
        final msg = data != null ? (data['error'] ?? data['message'] ?? 'Request failed') : 'Server error (${response.statusCode})';
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/verify-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      final data = _parseJson(response.body);
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'message': data['message']};
      } else {
        final msg = data != null ? (data['error'] ?? data['message'] ?? 'Verification failed') : 'Server error (${response.statusCode})';
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'newPassword': newPassword}),
      );
      final data = _parseJson(response.body);
      if (response.statusCode == 200 && data != null) {
        return {'success': true, 'message': data['message']};
      } else {
        final msg = data != null ? (data['error'] ?? data['message'] ?? 'Reset failed') : 'Server error (${response.statusCode})';
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // --- Predict API ---

  Future<Map<String, dynamic>> predict(String imagePath, String captureMethod) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not authenticated'};

      var request = http.MultipartRequest('POST', Uri.parse('${AppConstants.baseUrl}/predict'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['capture_method'] = captureMethod;
      final ext = imagePath.split('.').last.toLowerCase();
      final mediaType = ext == 'png' ? MediaType('image', 'png') : MediaType('image', 'jpeg');

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imagePath,
        contentType: mediaType,
      ));

      // 3-minute timeout to allow for CPU-based model inference
      var streamedResponse = await request.send().timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          throw Exception('Analysis is taking too long. Please try again.');
        },
      );
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401) {
        _handleUnauthorized();
        return {'success': false, 'message': 'Session expired. Please log in again.'};
      }

      final data = _parseJson(response.body);

      if (response.statusCode == 200 && data != null && data['result'] != null) {
        final resultJson = data['result'];
        print('=== FLUTTER: PREDICT RESPONSE ===');
        print('heatmap_url: "${resultJson['heatmap_url']}"');
        print('heatmap_base64: ${resultJson['heatmap_base64'] != null && resultJson['heatmap_base64'].toString().isNotEmpty ? "YES (length: ${resultJson['heatmap_base64'].toString().length})" : "EMPTY/NULL"}');
        return {
          'success': true,
          'result': PredictionResult.fromJson(resultJson)
        };
      } else {
        final errorMsg = data != null 
            ? (data['error'] ?? data['message'] ?? 'Prediction failed') 
            : 'Server error (${response.statusCode}): Response is not valid JSON';
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to process the image or AI service is unavailable.\nDetails: $e'};
    }
  }

  // --- History API ---

  Future<List<HistoryItem>> getHistory() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 401) {
        _handleUnauthorized();
        throw Exception('Session expired');
      }

      if (response.statusCode == 200) {
        final data = _parseJson(response.body);
        if (data == null) throw Exception('Invalid server response');
        final List<dynamic> historyJson = data['history'] ?? [];
        return historyJson.map((json) => HistoryItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load history (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<bool> deleteHistory(int id) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/history/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 401) {
        _handleUnauthorized();
        return false;
      }

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
