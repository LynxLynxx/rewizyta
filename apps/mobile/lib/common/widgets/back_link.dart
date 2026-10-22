import 'package:flutter/material.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';

/// "‹ Wstecz" in the app bar of a pushed screen. The design uses text and the
/// ‹ glyph instead of an arrow icon; screen readers hear only the word.
class const BackLink({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.maybePop(context),
      child: Text('‹ ${context.l10n.back}', semanticsLabel: context.l10n.back),
    );
  }
}
