import 'package:drift/drift.dart';

/// A calendar day as `YYYY-MM-DD`, the local and the Postgres `date` form.
///
/// Days are held as `DateTime.utc(y, m, d)`; only the calendar fields are read,
/// never the time zone, so a local midnight cannot shift the day.
String formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime parseDate(String text) {
  final parsed = DateTime.parse(text);
  return DateTime.utc(parsed.year, parsed.month, parsed.day);
}

/// An instant as ISO-8601 UTC text, the form drift stores and sync sends.
String formatTimestamp(DateTime timestamp) => timestamp.toUtc().toIso8601String();

DateTime parseTimestamp(String text) => DateTime.parse(text).toUtc();

/// An enum value as snake_case (`noShow` → `no_show`), the spelling of the
/// Postgres check constraints and the sync payloads.
String enumToSql(Enum value) =>
    value.name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

/// Stores a calendar day as `YYYY-MM-DD` text (see [formatDate]).
final class const DateConverter() extends TypeConverter<DateTime, String> {
  @override
  DateTime fromSql(String fromDb) => parseDate(fromDb);

  @override
  String toSql(DateTime value) => formatDate(value);
}

/// Stores an enum as its snake_case name (see [enumToSql]).
final class const EnumConverter<T extends Enum>(final List<T> _values)
    extends TypeConverter<T, String> {
  @override
  T fromSql(String fromDb) => _values.firstWhere(
    (value) => enumToSql(value) == fromDb,
    orElse: () => throw ArgumentError.value(fromDb, 'fromDb', 'Not a $T'),
  );

  @override
  String toSql(T value) => enumToSql(value);
}
