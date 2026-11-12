import 'package:flutter/material.dart';
import 'package:rewizyta/app/theme/app_colors.dart';
import 'package:rewizyta/app/theme/app_theme.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';

/// The tabs, in the order of the shell branches in `Routes`. Dziś joins in M4.
enum AppTab() {
  due,
  clients,
  more;

  String label(AppLocalizations l10n) => switch (this) {
    AppTab.due => l10n.dueTitle,
    AppTab.clients => l10n.clientsTitle,
    AppTab.more => l10n.moreTitle,
  };
}

/// The bottom navigation: a Material [NavigationBar] with text tabs, no icons;
/// the active one in ink, 600, under a 3 px accent bar (`docs/DESIGN_BRIEF.md`,
/// "The app"). Colours and label styles come from the theme's `navigationBarTheme`.
class const AppShell({
  super.key,
  required final AppTab current,
  required final ValueChanged<AppTab> onSelect,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const bar = SizedBox(width: AppSpacing.xl, height: 3);
    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.colorScheme.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: current.index,
          onDestinationSelected: (index) => onSelect(AppTab.values[index]),
          destinations: [
            for (final tab in AppTab.values)
              NavigationDestination(
                icon: bar,
                selectedIcon: ColoredBox(color: context.appColors.accent, child: bar),
                label: tab.label(context.l10n),
              ),
          ],
        ),
      ),
    );
  }
}
