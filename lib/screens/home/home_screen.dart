import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/images/skin_image.jpeg",
              fit: BoxFit.cover,
            ),
          ),

          // White Overlay
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                // Header
                Container(
                  height: 90,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xff8B6456),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "HOME",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xffFFF4E7),
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        children: [

                          menuButton(
                            Icons.image_outlined,
                            "Upload Existing\nImage",
                          ),

                          const SizedBox(height: 18),

                          menuButton(
                            Icons.camera_alt_outlined,
                            "Capture Skin\nImage",
                          ),

                          const SizedBox(height: 18),

                          menuButton(
                            Icons.remove_red_eye_outlined,
                            "View Past\nResult",
                          ),

                          const SizedBox(height: 18),

                          menuButton(
                            Icons.person_outline,
                            "Profile",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget menuButton(IconData icon, String title) {
    return Column(
      children: [

        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xff8B6456),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 70,
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          width: 150,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}