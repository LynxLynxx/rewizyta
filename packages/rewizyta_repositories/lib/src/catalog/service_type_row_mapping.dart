import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';

/// `service_types` row ↔ [ServiceType], shared by every query that reads or
/// writes the table: its repository, joins in other repositories, the sync.
/// Timestamps are written as UTC, so comparing the stored text compares
/// instants.
extension ServiceTypeRowMapping on ServiceTypeRow {
  ServiceType toDomain() => ServiceType(
    id: id,
    tradeId: tradeId,
    name: name,
    cycleMonths: cycleMonths,
    defaultPriceGrosze: defaultPriceGrosze,
    template: templateKey,
    sortOrder: sortOrder,
    isArchived: isArchived,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

extension ServiceTypeCompanionMapping on ServiceType {
  ServiceTypesCompanion toCompanion() => ServiceTypesCompanion.insert(
    id: id,
    tradeId: Value(tradeId),
    name: Value(name),
    cycleMonths: cycleMonths,
    defaultPriceGrosze: Value(defaultPriceGrosze),
    templateKey: Value(template),
    sortOrder: Value(sortOrder),
    isArchived: Value(isArchived),
    createdAt: createdAt.toUtc(),
    updatedAt: updatedAt.toUtc(),
    deletedAt: Value(deletedAt?.toUtc()),
  );
}
