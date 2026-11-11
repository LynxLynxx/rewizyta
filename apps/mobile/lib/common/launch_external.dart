import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hands [uri] (`tel:`, `sms:`) to the system dialer or messaging app, with a
/// snackbar when nothing takes it. Android throws when no app takes the
/// intent (a tablet without telephony), iOS returns false.
Future<void> launchExternal(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.l10n.clientLaunchFailed;
  final launched = await launchUrl(uri).onError<PlatformException>((_, _) => false);
  if (!launched) messenger.showSnackBar(SnackBar(content: Text(failed)));
}
