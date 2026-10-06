import 'package:drift/drift.dart';

/// Local-only queue of changes waiting to be pushed (docs/TRD.md,
/// "Outbox"). Every write to a synced table appends here in the same
/// transaction (`OutboxWriter.upsertSynced`); SyncService drains it.
@DataClassName('OutboxRow')
@TableIndex(name: 'outbox_entity_id', columns: {#entity, #entityId})
class Outbox() extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get op => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}
