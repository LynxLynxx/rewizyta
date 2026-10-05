import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';

/// `visits` row ↔ [Visit], shared by every query that reads or
/// writes the table: its repository, joins in other repositories, the sync.
/// Timestamps are written as UTC, so comparing the stored text compares
/// instants.
extension VisitRowMapping on VisitRow {
  Visit toDomain() => Visit(
    id: id,
    clientId: clientId,
    doneAt: doneAt,
    priceGrosze: priceGrosze,
    note: note,
    appointmentId: appointmentId,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

extension VisitCompanionMapping on Visit {
  VisitsCompanion toCompanion() => VisitsCompanion.insert(
    id: id,
    clientId: clientId,
    doneAt: doneAt,
    priceGrosze: Value(priceGrosze),
    note: Value(note),
    appointmentId: Value(appointmentId),
    createdAt: createdAt.toUtc(),
    updatedAt: updatedAt.toUtc(),
    deletedAt: Value(deletedAt?.toUtc()),
  );
}
