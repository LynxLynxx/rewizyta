import 'package:go_router/go_router.dart';
import 'package:rewizyta/router/root_navigator_key.dart';
import 'package:rewizyta/router/routes/routing/routes.dart';

/// Builds the app's [GoRouter] from [Routes]. Redirects (auth gate,
/// onboarding) plug in here with a `refreshListenable` adapter over the
/// session cubit (M5/M7).
abstract final class AppRouterFactory() {
  static GoRouter create({String? initialLocation}) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation ?? Routes.initialLocation,
      routes: Routes.routes,
    );
  }
}
