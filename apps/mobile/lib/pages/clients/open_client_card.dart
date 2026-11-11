import 'package:flutter/material.dart';
import 'package:rewizyta/router/routes/routing/clients_route.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';

/// Opens the client card. The card pops with `true` after a delete; the undo
/// is offered by the caller, whose cubit outlives the card.
Future<void> openClientCard(
  BuildContext context,
  String id, {
  required VoidCallback onUndo,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final deleted = await ClientDetailRoute(id: id).push<bool>(context);
  if (deleted != true) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(l10n.clientDeleted),
      action: SnackBarAction(label: l10n.undo, onPressed: onUndo),
    ),
  );
}
