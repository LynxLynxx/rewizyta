import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/appointment/appointment_row_mapping.dart';
import 'package:rewizyta_repositories/src/appointment/appointments_repository.dart';
import 'package:rewizyta_repositories/src/appointment/dto/appointment_dto.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';
import 'package:rewizyta_repositories/src/database/outbox_writer.dart';

/// Timestamps are stored as UTC ISO-8601 text, so the range comparison is a
/// text comparison; the bounds are converted to UTC for that reason.
final class const AppointmentsRepositoryImpl(final AppDatabase _db)
    implements AppointmentsRepository {
  @override
  Stream<List<Appointment>> watchBetween(DateTime from, DateTime to) {
    final query = _db.select(_db.appointments)
      ..where(
        (a) =>
            a.deletedAt.isNull() &
            a.startsAt.isBiggerOrEqualValue(from.toUtc()) &
            a.startsAt.isSmallerThanValue(to.toUtc()),
      )
      ..orderBy([(a) => OrderingTerm.asc(a.startsAt), (a) => OrderingTerm.asc(a.id)]);
    return query.watch().map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  @override
  Stream<List<Appointment>> watchByClient(String clientId) {
    final query = _db.select(_db.appointments)
      ..where((a) => a.clientId.equals(clientId) & a.deletedAt.isNull())
      ..orderBy([(a) => OrderingTerm.desc(a.startsAt)]);
    return query.watch().map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  @override
  Future<Appointment?> find(String id) async {
    final query = _db.select(_db.appointments)..where((a) => a.id.equals(id));
    final row = await query.getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> upsert(Appointment appointment) => _db.upsertSynced(
    _db.appointments,
    appointment.toCompanion(),
    id: appointment.id,
    isDeleted: appointment.isDeleted,
    payload: AppointmentDto.fromDomain(appointment).toJson(),
  );
}
