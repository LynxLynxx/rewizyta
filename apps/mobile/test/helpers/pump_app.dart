import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';

extension PumpApp on WidgetTester {
  /// Pumps [widget] under a MaterialApp with the app theme and localizations,
  /// so `context.l10n` and `context.appColors` work in widget tests.
  Future<void> pumpApp(Widget widget) async {
    await pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: widget,
      ),
    );
    await pump();
  }
}
