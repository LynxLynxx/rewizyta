import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';

/// `visit_items` row ↔ [VisitItem], shared by every query that reads or
/// writes the table: its repository, joins in other repositories, the sync.
/// Timestamps are written as UTC, so comparing the stored text compares
/// instants.
extension VisitItemRowMapping on VisitItemRow {
  VisitItem toDomain() => VisitItem(
    id: id,
    visitId: visitId,
    equipmentId: equipmentId,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

extension VisitItemCompanionMapping on VisitItem {
  VisitItemsCompanion toCompanion() => VisitItemsCompanion.insert(
    id: id,
    visitId: visitId,
    equipmentId: equipmentId,
    createdAt: createdAt.toUtc(),
    updatedAt: updatedAt.toUtc(),
    deletedAt: Value(deletedAt?.toUtc()),
  );
}
