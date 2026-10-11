import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),
                    
                    const Text(
                      'Create new account',
                      style: AppTextStyles.titleDark,
                    ),
                    
                    const SizedBox(height: 40),

                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Enter your email',
                    ),
                    
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _usernameController,
                      hintText: 'Enter your username',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Enter your password',
                      isPassword: true,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm password',
                      isPassword: true,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: size.width * 0.55,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () async {
                          setState(() {
                            _isLoading = true;
                          });
                          
                          final username = _usernameController.text.trim();
                          final email = _emailController.text.trim();
                          final password = _passwordController.text;
                          final confirmPassword = _confirmPasswordController.text;
                          
                          if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all fields')),
                            );
                            setState(() {
                              _isLoading = false;
                            });
                            return;
                          }

                          // Email validation Regex check
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(email)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid email address')),
                            );
                            setState(() {
                              _isLoading = false;
                            });
                            return;
                          }

                          final passwordError = Validators.validatePassword(password);
                          if (passwordError != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(passwordError)),
                            );
                            setState(() {
                              _isLoading = false;
                            });
                            return;
                          }

                          if (password != confirmPassword) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Passwords do not match')),
                            );
                            setState(() {
                              _isLoading = false;
                            });
                            return;
                          }

                          final result = await ApiService().register(username, email, password);
                          
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                            
                            if (result['success']) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Registration successful! Please login.')),
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result['message'])),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBrown,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27.5),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppColors.lightBackground, strokeWidth: 2))
                          : const Text(
                              'create account',
                              style: AppTextStyles.buttonTextLight,
                            ),
                      ),
                    ),
                    
                    const Spacer(flex: 2),
                    
                    const Text(
                      'Already have an account',
                      style: AppTextStyles.bodyGrey,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Login',
                        style: AppTextStyles.linkText,
                      ),
                    ),
                    
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
