final _typedDate = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$');

/// `DateTime.utc(2025, 10, 14)` → `14.10.2025`.
String formatDate(DateTime day) {
  String pad(int part) => '$part'.padLeft(2, '0');
  return '${pad(day.day)}.${pad(day.month)}.${day.year}';
}

/// Reads a typed `DD.MM.RRRR` as a calendar day, or null when it is not a real
/// date (`31.02.2026`).
DateTime? parseDate(String text) {
  final match = _typedDate.firstMatch(text.trim());
  if (match == null) return null;
  final day = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final date = DateTime.utc(int.parse(match[3]!), month, day);
  return date.day == day && date.month == month ? date : null;
}

/// The calendar day of a local moment, in the `DateTime.utc(y, m, d)` form due
/// dates are stored in.
DateTime calendarDay(DateTime moment) => DateTime.utc(moment.year, moment.month, moment.day);
