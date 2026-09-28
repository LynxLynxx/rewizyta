import 'package:rewizyta/app/bootstrap.dart';
import 'package:rewizyta/app/config/app_config.dart';

/// Nothing but the config literal; the start-up sequence is in bootstrap().
Future<void> main() => bootstrap(AppConfig.fromEnvironment());
