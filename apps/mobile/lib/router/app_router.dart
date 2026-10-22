import 'package:go_router/go_router.dart';
import 'package:rewizyta/pages/clients/client_detail_page.dart';
import 'package:rewizyta/pages/clients/client_form_page.dart';
import 'package:rewizyta/pages/clients/clients_page.dart';
import 'package:rewizyta/router/route_paths.dart';

/// Central route table. Redirects (auth gate, onboarding) plug in here with a
/// `refreshListenable` adapter over the session cubit (M5/M7). Child paths are
/// relative segments of [RoutePaths]; `new` comes before `:id`.
abstract final class AppRouter() {
  static final router = GoRouter(
    initialLocation: RoutePaths.clients,
    routes: [
      GoRoute(
        path: RoutePaths.clients,
        builder: (context, state) => const ClientsPage(),
        routes: [
          GoRoute(path: 'new', builder: (context, state) => const ClientFormPage()),
          GoRoute(
            path: ':id',
            builder: (context, state) => ClientDetailPage(id: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => ClientFormPage(id: state.pathParameters['id']),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
