import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';

/// `appointments` row ↔ [Appointment], shared by every query that reads or
/// writes the table: its repository, joins in other repositories, the sync.
/// Timestamps are written as UTC, so comparing the stored text compares
/// instants.
extension AppointmentRowMapping on AppointmentRow {
  Appointment toDomain() => Appointment(
    id: id,
    clientId: clientId,
    startsAt: startsAt,
    durationMinutes: durationMinutes,
    status: status,
    isTimeFixed: isTimeFixed,
    routePosition: routePosition,
    note: note,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

extension AppointmentCompanionMapping on Appointment {
  AppointmentsCompanion toCompanion() => AppointmentsCompanion.insert(
    id: id,
    clientId: clientId,
    startsAt: startsAt.toUtc(),
    durationMinutes: Value(durationMinutes),
    status: Value(status),
    isTimeFixed: Value(isTimeFixed),
    routePosition: Value(routePosition),
    note: Value(note),
    createdAt: createdAt.toUtc(),
    updatedAt: updatedAt.toUtc(),
    deletedAt: Value(deletedAt?.toUtc()),
  );
}
