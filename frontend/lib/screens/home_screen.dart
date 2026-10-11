import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/home_action_button.dart';
import 'upload_screen.dart';
import 'capture_screen.dart';
import 'past_results_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: [
          // Custom Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 10,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primaryBrown,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const Center(
              child: Text(
                'HOME',
                style: AppTextStyles.appBarTitle,
              ),
            ),
          ),
          
          // Body with background image and buttons
          Expanded(
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/home_bg.jpg',
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    cacheWidth: 1080,
                  ),
                ),
                
                // Action Buttons
                Align(
                  alignment: Alignment.centerLeft,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 30.0, top: 20.0, bottom: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HomeActionButton(
                            icon: Icons.image_outlined,
                            label: 'Upload Existing\nImage',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const UploadScreen()),
                              );
                            },
                          ),
                          HomeActionButton(
                            icon: Icons.camera_alt_outlined,
                            label: 'Capture Skin\nImage',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CaptureScreen()),
                              );
                            },
                          ),
                          HomeActionButton(
                            icon: Icons.remove_red_eye_outlined,
                            label: 'View Past\nResult',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PastResultsScreen()),
                              );
                            },
                          ),
                          HomeActionButton(
                            icon: Icons.person_outline,
                            label: 'Profile',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ProfileScreen()),
                              );
                            },
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
}
