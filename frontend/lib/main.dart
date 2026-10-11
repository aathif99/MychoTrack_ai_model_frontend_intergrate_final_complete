import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'utils/app_colors.dart';
import 'utils/navigator_key.dart';

void main() {
  runApp(const MycoTrackApp());
}

class MycoTrackApp extends StatelessWidget {
  const MycoTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Myco Track',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF865D4F)),
        useMaterial3: true,
      ),
      home: const AuthGate(), 
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache background and logo so they appear instantly with zero delay
    precacheImage(const AssetImage('assets/images/home_bg.jpg'), context);
    precacheImage(const AssetImage('assets/images/logo.png'), context);
  }

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // A brief delay to allow transitions to feel smooth and natural
    await Future.delayed(const Duration(milliseconds: 500));
    final isValid = await ApiService().verifyToken();
    if (!mounted) return;
    
    if (isValid) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.creamColor,
        ),
      ),
    );
  }
}
