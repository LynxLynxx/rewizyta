import 'package:drift/drift.dart';
import 'package:rewizyta_repositories/src/database/tables/synced_columns.dart';

/// Mirrors `public.clients` (docs/BACKEND_SCHEMA.md). The phone indexes for its own
/// queries: the list by name, the caller lookup by phone.
@DataClassName('ClientRow')
@TableIndex(name: 'clients_name', columns: {#name})
@TableIndex(name: 'clients_phone', columns: {#phone})
class Clients() extends Table with SyncedColumns {
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get addressLine => text().nullable()();
  TextColumn get town => text().nullable()();
  TextColumn get postalCode => text().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get contactId => text().nullable()();
}
