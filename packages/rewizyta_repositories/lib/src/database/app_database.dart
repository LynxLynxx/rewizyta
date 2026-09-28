import 'package:drift/drift.dart';
import 'package:rewizyta_repositories/src/database/tables/clients.dart';
import 'package:rewizyta_repositories/src/database/tables/outbox.dart';

part 'app_database.g.dart';

/// The one local database. The app passes the executor
/// (`driftDatabase(name: 'rewizyta')` on a phone, `NativeDatabase.memory()`
/// in tests), so this package stays free of Flutter.
@DriftDatabase(tables: [Clients, Outbox])
class AppDatabase(super.executor) extends _$AppDatabase {
  @override
  int get schemaVersion => 1;
}
