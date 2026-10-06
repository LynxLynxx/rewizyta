import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';

/// Operation recorded in the outbox. A delete is an upsert with `deleted_at`
/// set; the distinction only matters for logging.
enum OutboxOp() {
  upsert,
  delete,
}

extension OutboxWriter on AppDatabase {
  /// Writes a synced row and queues it for the push in one transaction
  /// (docs/TRD.md, "Outbox"). The outbox entity is the table name,
  /// which is also the Postgres table name.
  ///
  /// A pending entry for the same row is replaced: the payload is the whole
  /// row, so only the latest one needs to reach the server.
  Future<void> upsertSynced<T extends Table, D>(
    TableInfo<T, D> table,
    Insertable<D> row, {
    required String id,
    required bool isDeleted,
    required Map<String, dynamic> payload,
  }) {
    final entity = table.actualTableName;
    return transaction(() async {
      await into(table).insertOnConflictUpdate(row);
      await (delete(outbox)..where((o) => o.entity.equals(entity) & o.entityId.equals(id))).go();
      await into(outbox).insert(
        OutboxCompanion.insert(
          entity: entity,
          entityId: id,
          op: (isDeleted ? OutboxOp.delete : OutboxOp.upsert).name,
          payload: jsonEncode(payload),
          createdAt: DateTime.timestamp(),
        ),
      );
    });
  }
}
