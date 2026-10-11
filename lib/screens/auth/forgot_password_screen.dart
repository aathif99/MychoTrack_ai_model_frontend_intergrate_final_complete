import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_config.dart';
import '../auth/change_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  static const Color backgroundColor = Color(0xFFF4E8D2);
  static const Color brown = Color(0xFF7D5546);

  final TextEditingController emailController =
  TextEditingController();

  bool isLoading = false;

  Future<void> checkEmailAndContinue() async {
    FocusScope.of(context).unfocus();

    final email =
    emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      showMessage('Please enter your email address');
      return;
    }

    final emailPattern = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    if (!emailPattern.hasMatch(email)) {
      showMessage('Please enter a valid email address');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http
          .post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/auth/check-reset-email',
        ),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic> responseData = {};

      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          responseData = decoded;
        }
      }

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200 &&
          responseData['success'] == true) {
        final userData = responseData['user'];

        if (userData is! Map<String, dynamic>) {
          showMessage(
            'The server did not return the user information',
          );
          return;
        }

        final userId = userData['id'];
        final username =
            userData['username']?.toString() ?? '';

        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) =>
                ChangePasswordScreen(
                  userId: int.tryParse(userId.toString()) ?? 0,
                  email: email,
                  username: username,
                ),
          ),
        );
      } else {
        showMessage(
          responseData['message']?.toString() ??
              'Email address does not exist',
        );
      }
    } on FormatException {
      if (mounted) {
        showMessage(
          'The server returned an invalid response',
        );
      }
    } catch (error) {
      debugPrint(
        'Email check request failed: $error',
      );

      if (mounted) {
        showMessage(
          'Could not connect to the server. '
              'Check that MySQL and the backend are running.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Column(
              children: [
                const SizedBox(height: 80),

                const Text(
                  'Forgot Password',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: brown,
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'Enter your email address to reset '
                      'your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                TextField(
                  controller: emailController,
                  enabled: !isLoading,
                  keyboardType:
                  TextInputType.emailAddress,
                  textInputAction:
                  TextInputAction.done,
                  autocorrect: false,
                  onSubmitted: (_) {
                    if (!isLoading) {
                      checkEmailAndContinue();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                    const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.brown,
                        width: 1,
                      ),
                    ),
                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: brown,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 45),

                SizedBox(
                  width: 250,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : checkEmailAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      disabledBackgroundColor:
                      brown.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(30),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Change password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 45),

                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      color: brown,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}