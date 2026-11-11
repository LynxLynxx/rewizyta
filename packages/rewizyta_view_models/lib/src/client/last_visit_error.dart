import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_view_models/src/formatters/date_formatter.dart';

/// What is wrong with a typed "Ostatnia wizyta". An empty field is fine: the
/// due date then waits for the first visit.
enum LastVisitError() {
  invalid,
  future;

  /// The error for [text], or null when it can be saved.
  static LastVisitError? of(String text, DateTime today) {
    if (text.trim().isEmpty) return null;
    final date = parseDate(text);
    if (date == null) return LastVisitError.invalid;
    return date.isAfter(today) ? LastVisitError.future : null;
  }

  String localizedMessage(AppLocalizations l10n) => switch (this) {
    LastVisitError.invalid => l10n.clientFormLastVisitInvalid,
    LastVisitError.future => l10n.clientFormLastVisitFuture,
  };
}
