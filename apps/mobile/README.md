# apps/mobile – the Rewizyta app

Flutter app for Android (first) and iOS. Offline-first: cubits read drift
streams through services, and a sync service reconciles with Supabase when
there is a connection. See [`../../docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md).

```
lib/
  main.dart              one line: bootstrap(AppConfig.fromEnvironment())
  app/
    bootstrap.dart       the single start-up path
    app.dart             MaterialApp.router
    config/              AppConfig from --dart-define
    dependency/          Dependencies – the get_it container, registered bottom-up
    theme/               ThemeData, AppColors (ThemeExtension), AppSpacing
    integrations/        vendor SDK adapters (Sentry, PostHog, FCM) – M7
  common/handlers/       ErrorHandlerStateMixin, SignalHandlerStateMixin
  router/                GoRouter table and RoutePaths
  pages/<feature>/       XPage (provides the cubit) + XView (renders)
test/
  helpers/pump_app.dart  MaterialApp + theme + l10n for widget tests
  pages/<feature>/       widget tests with MockCubit
```

```bash
melos bootstrap && melos run gen && melos run l10n   # from the repo root
cd apps/mobile && flutter run --dart-define-from-file=../../.env
```
