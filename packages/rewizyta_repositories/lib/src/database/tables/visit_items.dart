import 'package:drift/drift.dart';
import 'package:rewizyta_repositories/src/database/tables/equipment.dart';
import 'package:rewizyta_repositories/src/database/tables/synced_columns.dart';
import 'package:rewizyta_repositories/src/database/tables/visits.dart';

/// Mirrors `public.visit_items`: one row per (visit, equipment), soft-deleted
/// rows included, so re-ticking an item restores its row.
@DataClassName('VisitItemRow')
@TableIndex(name: 'visit_items_equipment_id', columns: {#equipmentId})
class VisitItems() extends Table with SyncedColumns {
  TextColumn get visitId => text().references(
    Visits,
    #id,
    onDelete: KeyAction.cascade,
    initiallyDeferred: true,
  )();
  TextColumn get equipmentId => text().references(
    EquipmentTable,
    #id,
    onDelete: KeyAction.cascade,
    initiallyDeferred: true,
  )();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {visitId, equipmentId},
  ];
}
