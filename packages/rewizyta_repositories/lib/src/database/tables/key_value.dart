import 'package:drift/drift.dart';

/// Local-only bookkeeping of the sync: `last_pulled_at`, `last_push_at`,
/// `device_id` (docs/DATABASE.md, "sync_state").
@DataClassName('SyncStateRow')
class SyncState() extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Device-only preferences; never synced (docs/DATABASE.md, "app_settings").
@DataClassName('AppSettingRow')
class AppSettings() extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
