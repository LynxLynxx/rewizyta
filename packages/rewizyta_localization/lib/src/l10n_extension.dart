import 'package:flutter/widgets.dart';
import 'package:rewizyta_localization/generated/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  /// `context.l10n.someKey` - the only way widgets read user-facing text.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
