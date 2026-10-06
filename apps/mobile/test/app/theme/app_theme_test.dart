import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewizyta/app/theme/app_colors.dart';
import 'package:rewizyta/app/theme/app_theme.dart';

void main() {
  group('AppTheme.light', () {
    final theme = AppTheme.light();

    test('uses the design tokens', () {
      expect(theme.colorScheme.primary, const Color(0xFF1D1C1A));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF6F4EF));
      expect(theme.textTheme.bodyLarge?.fontFamily, AppFonts.sans);
    });

    test('registers AppColors', () {
      final colors = theme.extension<AppColors>()!;
      expect(colors.accent, const Color(0xFFEE8A3A));
      expect(colors.overdueForeground, const Color(0xFF8E2A1B));
    });
  });

  group('AppColors', () {
    final colors = AppTheme.light().extension<AppColors>()!;
    const black = Color(0xFF000000);

    test('copyWith replaces only the given field', () {
      final copy = colors.copyWith(accent: black);
      expect(copy.accent, black);
      expect(copy.text2, colors.text2);
    });

    test('lerp interpolates every field and keeps itself without another', () {
      final other = colors.copyWith(accent: black, doneForeground: black);
      expect(colors.lerp(other, 1).accent, black);
      expect(colors.lerp(other, 1).doneForeground, black);
      expect(colors.lerp(other, 0).accent, colors.accent);
      expect(colors.lerp(null, 0.5), same(colors));
    });
  });
}
