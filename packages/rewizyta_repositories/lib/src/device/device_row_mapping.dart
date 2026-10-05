import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';

/// `devices` row ↔ [Device], shared by every query that reads or
/// writes the table: its repository, joins in other repositories, the sync.
/// Timestamps are written as UTC, so comparing the stored text compares
/// instants.
extension DeviceRowMapping on DeviceRow {
  Device toDomain() => Device(
    id: id,
    platform: platform,
    pushToken: pushToken,
    pushProvider: pushProvider,
    appVersion: appVersion,
    lastSeenAt: lastSeenAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

extension DeviceCompanionMapping on Device {
  DevicesCompanion toCompanion() => DevicesCompanion.insert(
    id: id,
    platform: platform,
    pushToken: Value(pushToken),
    pushProvider: Value(pushProvider),
    appVersion: Value(appVersion),
    lastSeenAt: Value(lastSeenAt?.toUtc()),
    createdAt: createdAt.toUtc(),
    updatedAt: updatedAt.toUtc(),
    deletedAt: Value(deletedAt?.toUtc()),
  );
}
