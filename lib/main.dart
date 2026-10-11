import 'package:flutter/material.dart';
import 'package:mycotrack/screens/results/result_details_screen.dart';
import 'theme/app_theme.dart';
import 'screens/history/history_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/results/result_details_screen.dart';
import 'screens/results/live_result_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/new_password_screen.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/history/view_past_results_screen.dart';

void main() {
  runApp(const MycoTrack());
}

class MycoTrack extends StatelessWidget {
  const MycoTrack({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "MycoTrack",
      theme: AppTheme.lightTheme,
      home: const WelcomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MycoTrack"),
      ),
      body: const Center(
        child: Text(
          "Welcome to MycoTrack",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}


