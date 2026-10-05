import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';
import 'package:rewizyta_repositories/src/database/tables/synced_columns.dart';

/// Mirrors `public.devices`. Locally it holds only this phone's row.
@DataClassName('DeviceRow')
class Devices() extends Table with SyncedColumns {
  TextColumn get platform => text().map(const EnumConverter(DevicePlatform.values))();
  TextColumn get pushToken => text().nullable()();
  TextColumn get pushProvider => text().nullable().map(const EnumConverter(PushProvider.values))();
  TextColumn get appVersion => text().nullable()();
  DateTimeColumn get lastSeenAt => dateTime().nullable()();
}
