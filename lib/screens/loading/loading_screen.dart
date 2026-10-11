import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7ECD6),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // Circular Loading Indicator
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    strokeWidth: 8,
                    valueColor: AlwaysStoppedAnimation(
                      Color(0xFF8B6456),
                    ),
                    backgroundColor: Color(0xFFE7D5A8),
                  ),
                ),

                const SizedBox(height: 45),

                const Text(
                  "LOADING...",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 35),

                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: SizedBox(
                    width: 300,
                    height: 18,
                    child: const LinearProgressIndicator(
                      value: 0.55, // Demo progress
                      backgroundColor: Color(0xFF5E463D),
                      valueColor: AlwaysStoppedAnimation(
                        Color(0xFFE2C46C),
                      ),
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