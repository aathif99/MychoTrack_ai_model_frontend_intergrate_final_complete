import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../login/login_screen.dart';
import '../../services/api_config.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color backgroundColor = Color(0xFFF7ECD6);
  static const Color brown = Color(0xFF8B6456);

  final TextEditingController emailController =
  TextEditingController();

  final TextEditingController usernameController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  final TextEditingController confirmPasswordController =
  TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;
  bool hideConfirmPassword = true;

  String get backendBaseUrl => ApiConfig.baseUrl;

  bool isValidEmail(String email) {
    final emailPattern = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    return emailPattern.hasMatch(email);
  }

  Future<void> registerUser() async {
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim().toLowerCase();
    final username = usernameController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (email.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage('Please complete all fields');
      return;
    }

    if (!isValidEmail(email)) {
      showMessage('Enter a valid email address');
      return;
    }

    if (username.length < 3) {
      showMessage(
        'Username must contain at least 3 characters',
      );
      return;
    }

    if (password.length < 8) {
      showMessage(
        'Password must contain at least 8 characters',
      );
      return;
    }

    if (password != confirmPassword) {
      showMessage('Passwords do not match');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final uri = Uri.parse(
        '$backendBaseUrl/api/auth/register',
      );

      final response = await http
          .post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
        }),
      )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic> responseData = {};

      if (response.body.isNotEmpty) {
        final decodedResponse = jsonDecode(response.body);

        if (decodedResponse is Map<String, dynamic>) {
          responseData = decodedResponse;
        }
      }

      if (!mounted) {
        return;
      }

      if (response.statusCode == 201) {
        showMessage(
          responseData['message']?.toString() ??
              'Account created successfully',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const LoginScreen(),
          ),
        );
      } else {
        showMessage(
          responseData['message']?.toString() ??
              'Registration failed',
        );
      }
    } on FormatException {
      if (mounted) {
        showMessage(
          'The backend returned an invalid response',
        );
      }
    } catch (error) {
      debugPrint('Registration request failed: $error');

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

  InputDecoration buildInputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(
          color: Colors.grey,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(
          color: brown,
          width: 2,
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 35,
            ),
            child: Column(
              children: [
                const SizedBox(height: 90),

                const Text(
                  'Create new account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: brown,
                  ),
                ),

                const SizedBox(height: 70),

                // Email
                TextField(
                  controller: emailController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: buildInputDecoration(
                    hintText: 'Enter your email address',
                  ),
                ),

                const SizedBox(height: 25),

                // Username
                TextField(
                  controller: usernameController,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: buildInputDecoration(
                    hintText: 'Enter your username',
                  ),
                ),

                const SizedBox(height: 25),

                // Password
                TextField(
                  controller: passwordController,
                  enabled: !isLoading,
                  obscureText: hidePassword,
                  textInputAction: TextInputAction.next,
                  decoration: buildInputDecoration(
                    hintText: 'Enter your password',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Confirm password
                TextField(
                  controller: confirmPasswordController,
                  enabled: !isLoading,
                  obscureText: hideConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!isLoading) {
                      registerUser();
                    }
                  },
                  decoration: buildInputDecoration(
                    hintText: 'Confirm password',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hideConfirmPassword =
                          !hideConfirmPassword;
                        });
                      },
                      icon: Icon(
                        hideConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 70),

                SizedBox(
                  width: 230,
                  height: 55,
                  child: ElevatedButton(
                    onPressed:
                    isLoading ? null : registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      disabledBackgroundColor:
                      brown.withValues(alpha: 0.6),
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
                      'Create New Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 120),

                const Text(
                  'Already have an account',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) =>
                        const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: brown,
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