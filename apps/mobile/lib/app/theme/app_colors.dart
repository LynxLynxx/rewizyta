import 'package:flutter/material.dart';

/// Design tokens the Material scheme has no slot for (`docs/DESIGN_BRIEF.md`,
/// "Tokens"). Widgets read them through `context.appColors`; colour literals
/// never appear in widgets. The values are set in `AppTheme`.
@immutable
final class const AppColors({
  required final Color accent,
  required final Color accentText,
  required final Color selectedBackground,
  required final Color text2,
  required final Color overdueBackground,
  required final Color overdueForeground,
  required final Color soonBackground,
  required final Color soonForeground,
  required final Color laterBackground,
  required final Color laterForeground,
  required final Color doneBackground,
  required final Color doneForeground,
}) extends ThemeExtension<AppColors> {
  @override
  AppColors copyWith({
    Color? accent,
    Color? accentText,
    Color? selectedBackground,
    Color? text2,
    Color? overdueBackground,
    Color? overdueForeground,
    Color? soonBackground,
    Color? soonForeground,
    Color? laterBackground,
    Color? laterForeground,
    Color? doneBackground,
    Color? doneForeground,
  }) => AppColors(
    accent: accent ?? this.accent,
    accentText: accentText ?? this.accentText,
    selectedBackground: selectedBackground ?? this.selectedBackground,
    text2: text2 ?? this.text2,
    overdueBackground: overdueBackground ?? this.overdueBackground,
    overdueForeground: overdueForeground ?? this.overdueForeground,
    soonBackground: soonBackground ?? this.soonBackground,
    soonForeground: soonForeground ?? this.soonForeground,
    laterBackground: laterBackground ?? this.laterBackground,
    laterForeground: laterForeground ?? this.laterForeground,
    doneBackground: doneBackground ?? this.doneBackground,
    doneForeground: doneForeground ?? this.doneForeground,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      accent: mix(accent, other.accent),
      accentText: mix(accentText, other.accentText),
      selectedBackground: mix(selectedBackground, other.selectedBackground),
      text2: mix(text2, other.text2),
      overdueBackground: mix(overdueBackground, other.overdueBackground),
      overdueForeground: mix(overdueForeground, other.overdueForeground),
      soonBackground: mix(soonBackground, other.soonBackground),
      soonForeground: mix(soonForeground, other.soonForeground),
      laterBackground: mix(laterBackground, other.laterBackground),
      laterForeground: mix(laterForeground, other.laterForeground),
      doneBackground: mix(doneBackground, other.doneBackground),
      doneForeground: mix(doneForeground, other.doneForeground),
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}
