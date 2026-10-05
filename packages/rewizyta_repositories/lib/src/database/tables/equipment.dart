import 'package:drift/drift.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';
import 'package:rewizyta_repositories/src/database/tables/clients.dart';
import 'package:rewizyta_repositories/src/database/tables/service_types.dart';
import 'package:rewizyta_repositories/src/database/tables/synced_columns.dart';

/// Mirrors `public.equipment`; named `EquipmentTable` in Dart only so it does
/// not clash with the `Equipment` model. `last_visit_at` and `next_due_at` are
/// the due-date cache (docs/DATABASE.md, "Due dates"). A service type in use
/// cannot be deleted, only archived.
@DataClassName('EquipmentRow')
@TableIndex(name: 'equipment_client_id', columns: {#clientId})
@TableIndex(name: 'equipment_service_type_id', columns: {#serviceTypeId})
@TableIndex(name: 'equipment_next_due_at', columns: {#nextDueAt})
class EquipmentTable() extends Table with SyncedColumns {
  @override
  String get tableName => 'equipment';

  TextColumn get clientId => text().references(
    Clients,
    #id,
    onDelete: KeyAction.cascade,
    initiallyDeferred: true,
  )();
  TextColumn get serviceTypeId => text().references(
    ServiceTypes,
    #id,
    initiallyDeferred: true,
  )();
  TextColumn get label => text().nullable()();
  IntColumn get count => integer().withDefault(const Constant(1))();
  TextColumn get note => text().nullable()();
  TextColumn get lastVisitAt => text().nullable().map(const DateConverter())();
  TextColumn get nextDueAt => text().nullable().map(const DateConverter())();

  @override
  List<String> get customConstraints => ['CHECK (count > 0)'];
}
