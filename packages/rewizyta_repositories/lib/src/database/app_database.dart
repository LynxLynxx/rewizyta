import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';
import 'package:rewizyta_repositories/src/database/tables/appointments.dart';
import 'package:rewizyta_repositories/src/database/tables/clients.dart';
import 'package:rewizyta_repositories/src/database/tables/devices.dart';
import 'package:rewizyta_repositories/src/database/tables/equipment.dart';
import 'package:rewizyta_repositories/src/database/tables/key_value.dart';
import 'package:rewizyta_repositories/src/database/tables/outbox.dart';
import 'package:rewizyta_repositories/src/database/tables/reminders.dart';
import 'package:rewizyta_repositories/src/database/tables/service_types.dart';
import 'package:rewizyta_repositories/src/database/tables/trades.dart';
import 'package:rewizyta_repositories/src/database/tables/visit_items.dart';
import 'package:rewizyta_repositories/src/database/tables/visits.dart';

part 'app_database.g.dart';

/// The one local database. The app passes the executor
/// (`driftDatabase(name: 'rewizyta')` on a phone, `NativeDatabase.memory()`
/// in tests), so this package stays free of Flutter.
///
/// Foreign keys are enforced and deferred to the end of each transaction, so a
/// sync pull can apply rows in any order. No build has shipped yet, so schema
/// version 1 is still edited in place; from the first release on, every change
/// bumps [schemaVersion] with a migration (docs/BACKEND_SCHEMA.md, "Migrations").
@DriftDatabase(
  tables: [
    Clients,
    Trades,
    ServiceTypes,
    EquipmentTable,
    Appointments,
    Visits,
    VisitItems,
    Reminders,
    Devices,
    Outbox,
    SyncState,
    AppSettings,
  ],
)
class AppDatabase(super.executor) extends _$AppDatabase {
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
