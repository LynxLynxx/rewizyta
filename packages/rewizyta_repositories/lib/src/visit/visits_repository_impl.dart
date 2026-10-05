import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';
import 'package:rewizyta_repositories/src/database/outbox_writer.dart';
import 'package:rewizyta_repositories/src/visit/dto/visit_dto.dart';
import 'package:rewizyta_repositories/src/visit/visit_row_mapping.dart';
import 'package:rewizyta_repositories/src/visit/visits_repository.dart';

final class const VisitsRepositoryImpl(final AppDatabase _db) implements VisitsRepository {
  @override
  Stream<List<Visit>> watchByClient(String clientId) {
    final query = _db.select(_db.visits)
      ..where((v) => v.clientId.equals(clientId) & v.deletedAt.isNull())
      ..orderBy([(v) => OrderingTerm.desc(v.doneAt), (v) => OrderingTerm.desc(v.createdAt)]);
    return query.watch().map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  @override
  Future<Visit?> find(String id) async {
    final row = await (_db.select(_db.visits)..where((v) => v.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<DateTime?> lastDoneAt(String equipmentId) async {
    final items = _db.visitItems;
    final query =
        _db.select(_db.visits).join([innerJoin(items, items.visitId.equalsExp(_db.visits.id))])
          ..where(
            items.equipmentId.equals(equipmentId) &
                items.deletedAt.isNull() &
                _db.visits.deletedAt.isNull(),
          )
          // `YYYY-MM-DD` text sorts in calendar order.
          ..orderBy([OrderingTerm.desc(_db.visits.doneAt)])
          ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.readTable(_db.visits).doneAt;
  }

  @override
  Future<void> upsert(Visit visit) => _db.upsertSynced(
    _db.visits,
    visit.toCompanion(),
    id: visit.id,
    isDeleted: visit.isDeleted,
    payload: VisitDto.fromDomain(visit).toJson(),
  );
}
