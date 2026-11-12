import 'package:go_router/go_router.dart';
import 'package:rewizyta/pages/shell/app_shell.dart';
import 'package:rewizyta/router/routes/routing/clients_route.dart' as clients;
import 'package:rewizyta/router/routes/routing/due_route.dart' as due;
import 'package:rewizyta/router/routes/routing/more_route.dart' as more;

/// Every feature's generated `$appRoutes`, spread once each. A tab is one
/// shell branch, in [AppTab] order, so each keeps its own stack and scroll
/// position. A new feature adds a `<feature>_route.dart` next to this file and
/// one line here.
abstract final class Routes() {
  static final List<RouteBase> routes = [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(
        current: AppTab.values[shell.currentIndex],
        // A tap on the current tab goes back to its root.
        onSelect: (tab) => shell.goBranch(
          tab.index,
          initialLocation: tab.index == shell.currentIndex,
        ),
        child: shell,
      ),
      branches: [
        StatefulShellBranch(routes: due.$appRoutes),
        StatefulShellBranch(routes: clients.$appRoutes),
        StatefulShellBranch(routes: more.$appRoutes),
      ],
    ),
  ];

  static String get initialLocation => const clients.ClientsRoute().location;
}
