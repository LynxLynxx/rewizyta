import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:rewizyta/pages/catalog/catalog_page.dart';
import 'package:rewizyta/pages/more/more_page.dart';

part 'more_route.g.dart';

// The settings screens stay inside the tab, under the tab bar; their sheets
// cover it (`useRootNavigator`).
@TypedGoRoute<MoreRoute>(
  path: '/more',
  routes: [TypedGoRoute<CatalogRoute>(path: 'services')],
)
final class const MoreRoute() extends GoRouteData with $MoreRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) => const MorePage();
}

final class const CatalogRoute() extends GoRouteData with $CatalogRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) => const CatalogPage();
}
