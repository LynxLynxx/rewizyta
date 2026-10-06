import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';

/// `trades` row ↔ [Trade], shared by every query that reads or
/// writes the table: its repository, joins in other repositories, the sync.
/// Timestamps are written as UTC, so comparing the stored text compares
/// instants.
extension TradeRowMapping on TradeRow {
  Trade toDomain() => Trade(
    id: id,
    name: name,
    template: templateKey,
    sortOrder: sortOrder,
    isArchived: isArchived,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

extension TradeCompanionMapping on Trade {
  TradesCompanion toCompanion() => TradesCompanion.insert(
    id: id,
    name: Value(name),
    templateKey: Value(template),
    sortOrder: Value(sortOrder),
    isArchived: Value(isArchived),
    createdAt: createdAt.toUtc(),
    updatedAt: updatedAt.toUtc(),
    deletedAt: Value(deletedAt?.toUtc()),
  );
}
