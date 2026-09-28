import 'package:flutter/widgets.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_models/rewizyta_models.dart';

/// Inline field errors are state, not events: the enum lives in the domain,
/// the wording here.
extension ClientValidationErrorX on ClientValidationError {
  String localizedMessage(BuildContext context) => switch (this) {
    ClientValidationError.nameEmpty => context.l10n.validationNameEmpty,
    ClientValidationError.phoneInvalid => context.l10n.validationPhoneInvalid,
  };
}
