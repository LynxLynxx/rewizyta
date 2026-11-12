import 'package:flutter/material.dart';
import 'package:rewizyta/router/routes/routing/more_route.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';

/// Więcej: the screens used rarely. One row for now; reminders, the monthly
/// summary and the settings join it (`docs/APP_FLOW.md`).
class const MorePage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreTitle)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.catalogTitle),
            trailing: const ExcludeSemantics(child: Text('›')),
            onTap: () => const CatalogRoute().push<void>(context),
          ),
        ],
      ),
    );
  }
}
