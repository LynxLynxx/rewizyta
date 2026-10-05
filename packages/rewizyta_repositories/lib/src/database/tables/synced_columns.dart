import 'package:drift/drift.dart';

/// The columns every synced table carries (docs/DATABASE.md, "Principles").
///
/// `user_id` stays null on the phone until a pull fills it in; the server sets
/// it from the session whatever the payload says. Timestamps are UTC text
/// (`store_date_time_values_as_text` in build.yaml).
mixin SyncedColumns on Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
