import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:rewizyta/app/app.dart';
import 'package:rewizyta/app/config/app_config.dart';
import 'package:rewizyta/app/dependency/dependencies.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The one start-up path. Order matters: config, platform SDKs, DI, error
/// handlers, bloc observer, runApp.
Future<void> bootstrap(AppConfig config) async {
  ReportingService? reporting;

  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (config.hasSupabase) {
      await Supabase.initialize(url: config.supabaseUrl, publishableKey: config.supabaseKey);
    }

    await Dependencies.instance.init(config: config);

    reporting = Dependencies.instance.get<ReportingService>();
    await reporting!.init();
    await Dependencies.instance.get<AnalyticsService>().init();

    FlutterError.onError = (details) {
      unawaited(
        reporting!.recordError(
          details.exception,
          details.stack ?? StackTrace.current,
          reason: details.context?.toString(),
          fatal: true,
        ),
      );
      if (kDebugMode) FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(reporting!.recordError(error, stack, fatal: true));
      return true;
    };

    Bloc.observer = AppBlocObserver(reportingService: reporting);

    runApp(const App());
  }, (error, stack) => unawaited(reporting?.recordError(error, stack, fatal: true)));
}
