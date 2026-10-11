import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_config.dart';
import '../login/login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    required this.userId,
    required this.email,
    required this.username,
    super.key,
  });

  final int userId;
  final String email;
  final String username;

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  static const Color backgroundColor = Color(0xFFF5EBD5);
  static const Color brown = Color(0xFF7B5444);

  final TextEditingController passwordController =
  TextEditingController();

  final TextEditingController confirmPasswordController =
  TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;

  Future<void> savePassword() async {
    FocusScope.of(context).unfocus();

    final newPassword = passwordController.text;
    final confirmPassword =
        confirmPasswordController.text;

    if (newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage(
        'Enter and confirm your new password',
      );
      return;
    }

    if (newPassword.length < 8) {
      showMessage(
        'Password must contain at least 8 characters',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      showMessage('Passwords do not match');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http
          .post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/auth/reset-password-direct',
        ),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'userId': widget.userId,
          'email': widget.email,
          'newPassword': newPassword,
        }),
      )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic> responseData = {};

      if (response.body.isNotEmpty) {
        final decodedResponse =
        jsonDecode(response.body);

        if (decodedResponse
        is Map<String, dynamic>) {
          responseData = decodedResponse;
        }
      }

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200 &&
          responseData['success'] == true) {
        passwordController.clear();
        confirmPasswordController.clear();

        showMessage(
          responseData['message']?.toString() ??
              'Password changed successfully',
        );

        await Future<void>.delayed(
          const Duration(milliseconds: 700),
        );

        if (!mounted) {
          return;
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(
            builder: (context) =>
            const LoginScreen(),
          ),
              (route) => false,
        );
      } else {
        showMessage(
          responseData['message']?.toString() ??
              'Unable to change password',
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
        'Password reset request failed: $error',
      );

      if (mounted) {
        showMessage(
          'Could not connect to the server. '
              'Check that the backend and MySQL are running.',
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

  InputDecoration passwordDecoration({
    required String hintText,
    required bool hidden,
    required VoidCallback onVisibilityPressed,
  }) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFD8CFC8),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: brown,
          width: 2,
        ),
      ),
      suffixIcon: IconButton(
        onPressed: isLoading
            ? null
            : onVisibilityPressed,
        icon: Icon(
          hidden
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: brown,
        ),
      ),
    );
  }

  @override
  void dispose() {
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
          padding: const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 20,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: isLoading
                      ? null
                      : () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: brown,
                    size: 30,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.black,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 80,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                widget.username,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.blueGrey,
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                'Change Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: brown,
                ),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: passwordController,
                enabled: !isLoading,
                obscureText: hidePassword,
                textInputAction:
                TextInputAction.next,
                decoration: passwordDecoration(
                  hintText: 'Enter new password',
                  hidden: hidePassword,
                  onVisibilityPressed: () {
                    setState(() {
                      hidePassword =
                      !hidePassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller:
                confirmPasswordController,
                enabled: !isLoading,
                obscureText: hideConfirmPassword,
                textInputAction:
                TextInputAction.done,
                onSubmitted: (_) {
                  if (!isLoading) {
                    savePassword();
                  }
                },
                decoration: passwordDecoration(
                  hintText:
                  'Confirm new password',
                  hidden: hideConfirmPassword,
                  onVisibilityPressed: () {
                    setState(() {
                      hideConfirmPassword =
                      !hideConfirmPassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 70),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed:
                  isLoading ? null : savePassword,
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
                    'Save Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brown,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}