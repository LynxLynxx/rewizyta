import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';

/// `equipment` row ↔ [Equipment], shared by every query that reads or
/// writes the table: its repository, joins in other repositories, the sync.
/// Timestamps are written as UTC, so comparing the stored text compares
/// instants.
extension EquipmentRowMapping on EquipmentRow {
  Equipment toDomain() => Equipment(
    id: id,
    clientId: clientId,
    serviceTypeId: serviceTypeId,
    label: label,
    count: count,
    note: note,
    lastVisitAt: lastVisitAt,
    nextDueAt: nextDueAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

extension EquipmentCompanionMapping on Equipment {
  EquipmentTableCompanion toCompanion() => EquipmentTableCompanion.insert(
    id: id,
    clientId: clientId,
    serviceTypeId: serviceTypeId,
    label: Value(label),
    count: Value(count),
    note: Value(note),
    lastVisitAt: Value(lastVisitAt),
    nextDueAt: Value(nextDueAt),
    createdAt: createdAt.toUtc(),
    updatedAt: updatedAt.toUtc(),
    deletedAt: Value(deletedAt?.toUtc()),
  );
}
