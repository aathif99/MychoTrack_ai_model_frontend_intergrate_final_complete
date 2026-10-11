import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/forgot_password_screen.dart';
import '../home/home_screen.dart';
import '../new account/create_new_account_screen.dart';
import '../../services/api_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color backgroundColor = Color(0xFFF7ECD6);
  static const Color brown = Color(0xFF8B6456);
  static const Color darkBrown = Color(0xFF6D4C41);

  final TextEditingController usernameController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;

  String get backendBaseUrl => ApiConfig.baseUrl;

  Future<void> loginUser() async {
    FocusScope.of(context).unfocus();

    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      showMessage('Please enter your username and password');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final uri = Uri.parse(
        '$backendBaseUrl/api/auth/login',
      );

      final response = await http
          .post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic> responseData = {};

      if (response.body.isNotEmpty) {
        final decodedBody = jsonDecode(response.body);

        if (decodedBody is Map<String, dynamic>) {
          responseData = decodedBody;
        }
      }

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200 &&
          responseData['success'] == true) {
        showMessage(
          responseData['message']?.toString() ??
              'Login successful',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const HomeScreen(),
          ),
        );
      } else {
        showMessage(
          responseData['message']?.toString() ??
              'Login failed',
        );
      }
    } on FormatException {
      if (mounted) {
        showMessage('The server returned an invalid response');
      }
    } catch (error) {
      debugPrint('Login request failed: $error');

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

  InputDecoration inputDecoration({
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(
          color: Colors.grey,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(
          color: brown,
          width: 2,
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 50),

                const Text(
                  'Welcome to Myco Track',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    color: brown,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'serif',
                  ),
                ),

                const SizedBox(height: 80),

                TextField(
                  controller: usernameController,
                  enabled: !isLoading,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: inputDecoration(
                    hintText: 'Enter your username',
                  ),
                ),

                const SizedBox(height: 25),

                TextField(
                  controller: passwordController,
                  enabled: !isLoading,
                  obscureText: hidePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!isLoading) {
                      loginUser();
                    }
                  },
                  decoration: inputDecoration(
                    hintText: 'Enter your password',
                    suffixIcon: IconButton(
                      onPressed: isLoading
                          ? null
                          : () {
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

                const SizedBox(height: 15),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) =>
                          const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot password',
                      style: TextStyle(
                        color: darkBrown,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: 220,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : loginUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      disabledBackgroundColor:
                      brown.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: 220,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                      Navigator.maybePop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 120),

                const Text(
                  "Don't have an account?",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) =>
                        const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Create a new account',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkBrown,
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