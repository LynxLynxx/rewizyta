import 'package:flutter/material.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta/router/app_router.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';

class const App({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: AppRouter.router,
    );
  }
}
