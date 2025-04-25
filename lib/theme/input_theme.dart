import 'package:flutter/material.dart';
import 'color_theme.dart';

class AppInputTheme {
  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
        filled: true,
        fillColor: ColorTheme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorTheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorTheme.error, width: 2),
        ),
        labelStyle: const TextStyle(color: ColorTheme.onBackground),
        hintStyle: TextStyle(color: ColorTheme.onBackground.withOpacity(0.5)),
        errorStyle: const TextStyle(color: ColorTheme.error),
        suffixIconColor: ColorTheme.onBackground,
        prefixIconColor: ColorTheme.onBackground,
      );
} 