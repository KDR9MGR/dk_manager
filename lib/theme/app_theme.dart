import 'package:flutter/material.dart';
import 'button_theme.dart';
import 'color_theme.dart';
import 'text_theme.dart';
import 'input_theme.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ColorTheme.background,
      primaryColor: ColorTheme.primary,
      colorScheme: ColorScheme.dark(
        primary: ColorTheme.primary,
        secondary: ColorTheme.secondary,
        surface: ColorTheme.surface,
        error: ColorTheme.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ColorTheme.surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextTheme.titleLarge.copyWith(
          color: ColorTheme.onSurface,
        ),
      ),
      textTheme: AppTextTheme.textTheme,
      elevatedButtonTheme: AppButtonTheme.elevatedButtonTheme,
      outlinedButtonTheme: AppButtonTheme.outlinedButtonTheme,
      textButtonTheme: AppButtonTheme.textButtonTheme,
      inputDecorationTheme: AppInputTheme.inputDecorationTheme,
      cardTheme: CardTheme(
        color: ColorTheme.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: ColorTheme.divider,
        thickness: 1,
      ),
    );
  }
} 