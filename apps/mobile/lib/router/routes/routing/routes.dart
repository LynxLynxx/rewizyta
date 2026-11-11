import 'package:go_router/go_router.dart';
import 'package:rewizyta/router/routes/routing/clients_route.dart' as clients;

/// Every feature's generated `$appRoutes`, spread once each. A new feature adds
/// a `<feature>_route.dart` next to this file and one line here.
abstract final class Routes() {
  static final List<RouteBase> routes = [
    ...clients.$appRoutes,
  ];

  static String get initialLocation => const clients.ClientsRoute().location;
}
