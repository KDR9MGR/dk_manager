import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2196F3);
  static const secondary = Color(0xFF03A9F4);
  static const accent = Color(0xFF00BCD4);
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const error = Color(0xFFB00020);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
}

class AppTextStyles {
  static const headline1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.surface,
  );

  static const headline2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const headline3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const body1 = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const body2 = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
}

class AppDimensions {
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 16.0;

  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
}

class AppStrings {
  static const appName = 'DK Manager';
  static const welcome = 'Welcome to DK Manager';
  static const login = 'Login';
  static const register = 'Register';
  static const email = 'Email';
  static const password = 'Password';
  static const name = 'Name';
  static const forgotPassword = 'Forgot Password?';
  static const noAccount = 'Don\'t have an account?';
  static const hasAccount = 'Already have an account?';
  static const signUp = 'Sign Up';
  static const signIn = 'Sign In';
  static const logout = 'Logout';
  static const profile = 'Profile';
  static const settings = 'Settings';
  static const addCase = 'Add Case';
  static const editCase = 'Edit Case';
  static const deleteCase = 'Delete Case';
  static const search = 'Search cases...';
  static const brand = 'Brand';
  static const model = 'Model';
  static const quantity = 'Quantity';
  static const price = 'Price';
  static const description = 'Description';
  static const image = 'Image';
  static const save = 'Save';
  static const cancel = 'Cancel';
  static const delete = 'Delete';
  static const confirm = 'Confirm';
} 