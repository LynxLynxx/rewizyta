import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:rewizyta/pages/clients/client_detail_page.dart';
import 'package:rewizyta/pages/clients/client_form_page.dart';
import 'package:rewizyta/pages/clients/clients_page.dart';
import 'package:rewizyta/router/root_navigator_key.dart';

part 'clients_route.g.dart';

// The card and the forms cover the tab bar (on [rootNavigatorKey]).
// `new` comes before `:id`, or `/clients/new` would open a client called "new".
@TypedGoRoute<ClientsRoute>(
  path: '/clients',
  routes: [
    TypedGoRoute<ClientNewRoute>(path: 'new'),
    TypedGoRoute<ClientDetailRoute>(
      path: ':id',
      routes: [TypedGoRoute<ClientEditRoute>(path: 'edit')],
    ),
  ],
)
final class const ClientsRoute() extends GoRouteData with $ClientsRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) => const ClientsPage();
}

/// Pops with the new client's id.
final class const ClientNewRoute() extends GoRouteData with $ClientNewRoute {
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) => const ClientFormPage();
}

/// Pops with `true` after a delete.
final class const ClientDetailRoute({required final String id})
    extends GoRouteData
    with $ClientDetailRoute {
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) => ClientDetailPage(id: id);
}

final class const ClientEditRoute({required final String id})
    extends GoRouteData
    with $ClientEditRoute {
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) => ClientFormPage(id: id);
}
