import 'package:rewizyta_localization/rewizyta_localization.dart';

const _weekdayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

/// `09:30`, in the phone's local time.
String formatTime(DateTime instant) {
  final local = instant.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)}';
}

/// `29.09`, for the local day of [instant].
String formatDayMonth(DateTime instant) {
  final local = instant.toLocal();
  return '${_two(local.day)}.${_two(local.month)}';
}

/// `pn`, for the local day of [instant].
String formatWeekday(AppLocalizations l10n, DateTime instant) =>
    l10n.weekdayShort(_weekdayKeys[instant.toLocal().weekday - 1]);

/// `pn 29.09, 09:30`: how a booking reads on the card and in the sheet.
String formatBooking(AppLocalizations l10n, DateTime instant) =>
    '${formatWeekday(l10n, instant)} ${formatDayMonth(instant)}, ${formatTime(instant)}';

String _two(int value) => value.toString().padLeft(2, '0');
