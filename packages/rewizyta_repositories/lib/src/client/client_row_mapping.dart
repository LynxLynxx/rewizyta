import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';

/// `clients` row ↔ [Client], shared by every query that reads or
/// writes the table: its repository, joins in other repositories, the sync.
/// Timestamps are written as UTC, so comparing the stored text compares
/// instants.
extension ClientRowMapping on ClientRow {
  Client toDomain() => Client(
    id: id,
    name: name,
    phone: phone,
    addressLine: addressLine,
    town: town,
    postalCode: postalCode,
    lat: lat,
    lng: lng,
    note: note,
    contactId: contactId,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

extension ClientCompanionMapping on Client {
  ClientsCompanion toCompanion() => ClientsCompanion.insert(
    id: id,
    name: name,
    phone: Value(phone),
    addressLine: Value(addressLine),
    town: Value(town),
    postalCode: Value(postalCode),
    lat: Value(lat),
    lng: Value(lng),
    note: Value(note),
    contactId: Value(contactId),
    createdAt: createdAt.toUtc(),
    updatedAt: updatedAt.toUtc(),
    deletedAt: Value(deletedAt?.toUtc()),
  );
}
