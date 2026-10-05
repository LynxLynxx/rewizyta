import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';
import 'package:rewizyta_repositories/src/database/outbox_writer.dart';
import 'package:rewizyta_repositories/src/visit/dto/visit_item_dto.dart';
import 'package:rewizyta_repositories/src/visit/visit_item_row_mapping.dart';
import 'package:rewizyta_repositories/src/visit/visit_items_repository.dart';

final class const VisitItemsRepositoryImpl(final AppDatabase _db) implements VisitItemsRepository {
  @override
  Future<List<VisitItem>> findByVisit(String visitId) async {
    final query = _db.select(_db.visitItems)
      ..where((i) => i.visitId.equals(visitId))
      ..orderBy([(i) => OrderingTerm.asc(i.createdAt), (i) => OrderingTerm.asc(i.id)]);
    final rows = await query.get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<void> upsert(VisitItem item) => _db.upsertSynced(
    _db.visitItems,
    item.toCompanion(),
    id: item.id,
    isDeleted: item.isDeleted,
    payload: VisitItemDto.fromDomain(item).toJson(),
  );
}
