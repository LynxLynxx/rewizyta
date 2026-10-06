import 'package:flutter/material.dart';
import 'package:rewizyta/app/theme/app_colors.dart';

/// The design system's raw tokens (`docs/DESIGN_BRIEF.md`, "Tokens"). Private:
/// widgets go through `context.colorScheme` and `context.appColors`.
abstract final class _Palette() {
  static const paper = Color(0xFFF6F4EF);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1D1C1A);
  static const text2 = Color(0xFF3E3B36);
  static const muted = Color(0xFF5E5A53);
  static const line = Color(0xFFDAD5CB);
  static const lineLight = Color(0xFFECE8E0);
  static const inputBorder = Color(0xFFA8A296);
  static const placeholder = Color(0xFF8A857C);
  static const selectedBg = Color(0xFFFDF1E6);
  static const accent = Color(0xFFEE8A3A);
  static const accentBg = Color(0xFFFBE3CF);
  static const accentOnBg = Color(0xFF8A3F0C);
  static const accentText = Color(0xFF9A4A12);
  static const ok = Color(0xFF3D8B55);
  static const okBg = Color(0xFFDCEEDF);
  static const okOnBg = Color(0xFF245B34);
  static const error = Color(0xFFB23A28);
  static const errorBg = Color(0xFFF7D9D3);
  static const errorOnBg = Color(0xFF8E2A1B);
}

/// Light only: the design has no dark theme yet (`docs/DESIGN_BRIEF.md`).
abstract final class AppTheme() {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: _Palette.ink,
      onPrimary: _Palette.paper,
      primaryContainer: _Palette.selectedBg,
      onPrimaryContainer: _Palette.ink,
      secondary: _Palette.ink,
      onSecondary: _Palette.paper,
      secondaryContainer: _Palette.selectedBg,
      onSecondaryContainer: _Palette.ink,
      tertiary: _Palette.accent,
      onTertiary: _Palette.ink,
      error: _Palette.error,
      onError: _Palette.white,
      errorContainer: _Palette.errorBg,
      onErrorContainer: _Palette.errorOnBg,
      surface: _Palette.paper,
      onSurface: _Palette.ink,
      onSurfaceVariant: _Palette.muted,
      surfaceContainerLowest: _Palette.white,
      surfaceContainerLow: _Palette.white,
      surfaceContainer: _Palette.white,
      surfaceContainerHigh: _Palette.lineLight,
      surfaceContainerHighest: _Palette.lineLight,
      outline: _Palette.inputBorder,
      outlineVariant: _Palette.line,
      inverseSurface: _Palette.ink,
      onInverseSurface: _Palette.paper,
      shadow: _Palette.ink,
      scrim: _Palette.ink,
      surfaceTint: Color(0x00000000),
    );
    const colors = AppColors(
      accent: _Palette.accent,
      accentText: _Palette.accentText,
      selectedBackground: _Palette.selectedBg,
      text2: _Palette.text2,
      overdueBackground: _Palette.errorBg,
      overdueForeground: _Palette.errorOnBg,
      soonBackground: _Palette.accentBg,
      soonForeground: _Palette.accentOnBg,
      laterBackground: _Palette.lineLight,
      laterForeground: _Palette.text2,
      doneBackground: _Palette.okBg,
      doneForeground: _Palette.okOnBg,
    );
    const controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
    );
    final textTheme = _textTheme();
    final buttonText = textTheme.labelLarge;

    return ThemeData(
      colorScheme: scheme,
      fontFamily: AppFonts.sans,
      textTheme: textTheme,
      extensions: const [colors],
      scaffoldBackgroundColor: _Palette.paper,
      appBarTheme: AppBarTheme(
        backgroundColor: _Palette.paper,
        foregroundColor: _Palette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _Palette.ink,
          foregroundColor: _Palette.paper,
          disabledBackgroundColor: _Palette.lineLight,
          disabledForegroundColor: _Palette.placeholder,
          minimumSize: const Size.fromHeight(54),
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _Palette.ink,
          backgroundColor: _Palette.white,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: _Palette.ink, width: 1.5),
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _Palette.ink,
          minimumSize: const Size(48, 48),
          textStyle: buttonText,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _Palette.ink,
        foregroundColor: _Palette.paper,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: controlShape,
      ),
      cardTheme: const CardThemeData(
        color: _Palette.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
          side: BorderSide(color: _Palette.line),
        ),
      ),
      dividerTheme: const DividerThemeData(color: _Palette.line, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        minTileHeight: 64,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: _Palette.muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _Palette.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        hintStyle: textTheme.bodyLarge?.copyWith(color: _Palette.placeholder),
        border: _inputBorder(_Palette.inputBorder),
        enabledBorder: _inputBorder(_Palette.inputBorder),
        focusedBorder: _inputBorder(_Palette.ink),
        errorBorder: _inputBorder(_Palette.error),
        focusedErrorBorder: _inputBorder(_Palette.error),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _Palette.white,
        selectedColor: _Palette.selectedBg,
        side: const BorderSide(color: _Palette.line),
        shape: controlShape,
        labelStyle: textTheme.bodyMedium,
        showCheckmark: false,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(_Palette.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? _Palette.ok : _Palette.inputBorder,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Color(0x00000000)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _Palette.accent,
        linearTrackColor: _Palette.lineLight,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _Palette.paper,
        elevation: 0,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _Palette.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: _Palette.paper),
        actionTextColor: _Palette.accent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
        ),
      ),
    );
  }

  /// The type scale in Material roles: screenTitle → headlineMedium, h3 →
  /// titleLarge, listTitle → titleMedium… Display and h2 are website-only.
  /// The family is set here, not only on `ThemeData`: component themes use
  /// these styles as they are, and `ThemeData(fontFamily:)` never reaches them.
  static TextTheme _textTheme() {
    const ink = _Palette.ink;
    return const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: ink,
      ),
      titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, height: 1.25, color: ink),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ink),
      bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, height: 1.5, color: ink),
      bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: ink),
      bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: ink),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ink),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.52,
        color: ink,
      ),
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ink),
    ).apply(fontFamily: AppFonts.sans);
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.control)),
    borderSide: BorderSide(color: color, width: 1.5),
  );
}

/// Font families bundled in `apps/mobile/assets/fonts/`. Mono is for dates,
/// times, phone numbers, codes, km and counts:
/// `style.copyWith(fontFamily: AppFonts.mono)`.
abstract final class AppFonts() {
  static const sans = 'IBM Plex Sans';
  static const mono = 'IBM Plex Mono';
}

/// Spacing scale; use these instead of magic numbers in paddings.
abstract final class AppSpacing() {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Corner radii from the design tokens.
abstract final class AppRadius() {
  static const double tag = 5;
  static const double inline = 8;
  static const double control = 10;
  static const double card = 12;
  static const double cardLarge = 14;
  static const double sheet = 20;
}
