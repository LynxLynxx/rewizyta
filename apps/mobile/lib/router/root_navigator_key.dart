import 'package:flutter/widgets.dart';

/// The navigator above the tab shell. Routes that set it as their
/// `$parentNavigatorKey` cover the tab bar (the client card and the forms,
/// `docs/APP_FLOW.md`, "Navigation").
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
