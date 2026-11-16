import 'package:equatable/equatable.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_view_models/src/formatters/booking_formatter.dart';

/// One day in the booking sheet's picker.
final class const BookingDayViewModel({
  /// A local calendar day.
  required final DateTime date,

  /// Visits already booked that day, the client's own booking left out.
  required final int visitCount,
}) with Equatable {
  /// `pn 29.09`.
  String dateLabel(AppLocalizations l10n) => '${formatWeekday(l10n, date)} ${formatDayMonth(date)}';

  /// `3 wiz.`, or `wolne` for a day with nothing booked.
  String countLabel(AppLocalizations l10n) =>
      visitCount == 0 ? l10n.bookingDayFree : l10n.bookingDayCount(visitCount);

  @override
  List<Object?> get props => [date, visitCount];
}
