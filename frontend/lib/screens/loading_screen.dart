import 'package:flutter/material.dart';
import '../models/prediction_result.dart';
import 'analysis_result_screen.dart';

class LoadingScreen extends StatefulWidget {
  final PredictionResult? predictionResult;
  const LoadingScreen({super.key, this.predictionResult});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate network/analysis delay, then navigate to result
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        if (widget.predictionResult != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AnalysisResultScreen(
                predictionResult: widget.predictionResult!,
              ),
            ),
          );
        } else {
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using a solid color that resembles the paper texture in the mockup
      backgroundColor: const Color(0xFFD0B49F),
      body: Stack(
        children: [
          // Optional: If you have a paper texture asset, it would go here.
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 3D Circular Loading Image Placeholder
                Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 150,
                      color: Color(0xFF8B5A3A),
                    ), // Placeholder icon
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // LOADING... Text
                const Text(
                  'LOADING...',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: Color(0xFF4A3022), // Dark brown color matching the image
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Custom Glowing Progress Bar
                Container(
                  width: 280,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E2310), // Deep dark brown for the empty track
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF5A3921), // Slightly lighter brown border
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 180, // Simulated progress (about 60%)
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFD3791B), // Deep orange
                              Color(0xFFFFC045), // Bright glowing gold/yellow
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFC045).withValues(alpha: 0.6), // Glow effect
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
