import 'package:flutter/material.dart';
import 'package:rewizyta/app/theme/app_colors.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';

/// The tabs, in the order of the shell branches in `Routes`. Dziś and Więcej join in M4 and M7.
enum AppTab() {
  due,
  clients;

  String label(AppLocalizations l10n) => switch (this) {
    AppTab.due => l10n.dueTitle,
    AppTab.clients => l10n.clientsTitle,
  };
}

/// The bottom navigation: text tabs, no icons; the active one in ink, 600,
/// over a 3 px accent bar (`docs/DESIGN_BRIEF.md`, "The app").
class const AppShell({
  super.key,
  required final AppTab current,
  required final ValueChanged<AppTab> onSelect,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          border: Border(top: BorderSide(color: context.colorScheme.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (final tab in AppTab.values)
                Expanded(
                  child: _Tab(
                    label: tab.label(context.l10n),
                    isSelected: tab == current,
                    onTap: () => onSelect(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class const _Tab({
  required final String label,
  required final bool isSelected,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  width: 3,
                  color: isSelected
                      ? context.appColors.accent
                      : context.colorScheme.surfaceContainerLowest,
                ),
              ),
            ),
            // heightFactor: the bar gets the screen's height; take only the text's.
            child: Center(
              heightFactor: 1,
              child: Text(
                label,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? context.colorScheme.onSurface
                      : context.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
