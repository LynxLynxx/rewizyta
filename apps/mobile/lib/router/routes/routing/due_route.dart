import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:rewizyta/pages/due/due_page.dart';

part 'due_route.g.dart';

@TypedGoRoute<DueRoute>(path: '/due')
final class const DueRoute() extends GoRouteData with $DueRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) => const DuePage();
}
