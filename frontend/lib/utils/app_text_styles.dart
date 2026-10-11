import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w400,
    color: AppColors.creamColor,
    fontFamily: 'Times New Roman', // Can be replaced with a specific serif font from Google Fonts like Playfair Display
    height: 1.2,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.buttonText,
  );

  // New text styles for Register Screen
  static const TextStyle titleDark = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryBrown,
  );

  static const TextStyle buttonTextLight = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.lightBackground,
  );

  static const TextStyle hintStyle = TextStyle(
    fontSize: 16,
    color: AppColors.hintText,
  );

  static const TextStyle bodyGrey = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.greyText,
  );

  static const TextStyle linkText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBrown,
  );

  // New text styles for Login Screen
  static const TextStyle welcomeTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.normal,
    color: AppColors.primaryBrown,
    fontFamily: 'Federant', 
  );

  static const TextStyle forgotPassword = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBrown,
  );

  // New text styles for Home Screen
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 44,
    color: AppColors.lightBackground,
    fontFamily: 'Federant',
  );

  static const TextStyle actionButtonLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryBrown,
    height: 1.1,
  );
}
