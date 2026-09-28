import 'package:go_router/go_router.dart';
import 'package:rewizyta/pages/clients/clients_page.dart';
import 'package:rewizyta/router/route_paths.dart';

/// Central route table. Redirects (auth gate, onboarding) plug in here with a
/// `refreshListenable` adapter over the session cubit (M5/M7).
abstract final class AppRouter() {
  static final router = GoRouter(
    initialLocation: RoutePaths.clients,
    routes: [GoRoute(path: RoutePaths.clients, builder: (context, state) => const ClientsPage())],
  );
}
