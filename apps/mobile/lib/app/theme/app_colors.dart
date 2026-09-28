import 'package:flutter/material.dart';

/// Semantic colours the Material scheme has no slot for. Widgets read them
/// through `context.appColors`; `Colors.*` literals never appear in widgets.
@immutable
final class const AppColors({
  required final Color overdue,
  required final Color dueSoon,
  required final Color booked,
}) extends ThemeExtension<AppColors> {
  static const light = AppColors(
    overdue: Color(0xFFB3261E),
    dueSoon: Color(0xFFB26A00),
    booked: Color(0xFF1B6E3A),
  );

  static const dark = AppColors(
    overdue: Color(0xFFF2B8B5),
    dueSoon: Color(0xFFFFD59A),
    booked: Color(0xFF9BDDB0),
  );

  @override
  AppColors copyWith({Color? overdue, Color? dueSoon, Color? booked}) => AppColors(
    overdue: overdue ?? this.overdue,
    dueSoon: dueSoon ?? this.dueSoon,
    booked: booked ?? this.booked,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      overdue: Color.lerp(overdue, other.overdue, t)!,
      dueSoon: Color.lerp(dueSoon, other.dueSoon, t)!,
      booked: Color.lerp(booked, other.booked, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}
