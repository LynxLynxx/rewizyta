import 'package:flutter/material.dart';
import 'package:rewizyta/app/theme/app_colors.dart';

abstract final class AppTheme() {
  static const _seed = Color(0xFF1F5F8B);

  static ThemeData light() => _build(Brightness.light, AppColors.light);

  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors colors) {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    return ThemeData(colorScheme: scheme, extensions: [colors]);
  }
}

/// Spacing scale; use these instead of magic numbers in paddings.
abstract final class AppSpacing() {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}
