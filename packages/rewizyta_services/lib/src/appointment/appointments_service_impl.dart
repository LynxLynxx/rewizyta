import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:rewizyta_services/src/appointment/appointments_service.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:uuid/uuid.dart';

/// The settings are the schema defaults until `profiles` reaches the phone (M5)
/// and gets an editor (M7).
final class AppointmentsServiceImpl(
  final AppointmentsRepository _appointments,
  final TransactionRunner _transaction, {
  PlannerSettings settings = const PlannerSettings(),
  DateTime Function()? now,
  Uuid? uuid,
}) implements AppointmentsService {
  final PlannerSettings _settings = settings;
  final DateTime Function() _now = now ?? DateTime.timestamp;
  final Uuid _uuid = uuid ?? const Uuid();

  @override
  Stream<Appointment?> watchOpenBooking(String clientId) =>
      _appointments.watchByClient(clientId).map(_openBooking);

  /// "Today" is read on each emission, so after midnight yesterday's
  /// unrecorded booking keeps its tag until the next write; the same limit as
  /// [watchOpenBooking].
  @override
  Stream<Map<String, Appointment>> watchOpenBookings() =>
      _appointments.watchPlanned().map((planned) {
        final byClient = <String, List<Appointment>>{};
        for (final appointment in planned) {
          (byClient[appointment.clientId] ??= []).add(appointment);
        }
        return {
          for (final MapEntry(:key, :value) in byClient.entries) key: ?_openBooking(value),
        };
      });

  @override
  Future<Appointment> book({
    required String clientId,
    required DateTime startsAt,
    bool isTimeFixed = false,
  }) {
    final now = _now();
    if (!startsAt.isAfter(now)) {
      throw const AppointmentValidationException(AppointmentValidationError.inPast);
    }
    return _transaction.run(() async {
      final open = _openBooking(await _appointments.findByClient(clientId));
      final booking = open == null
          ? Appointment(
              id: _uuid.v4(),
              clientId: clientId,
              startsAt: startsAt.toUtc(),
              durationMinutes: _settings.slotMinutes,
              isTimeFixed: isTimeFixed,
              createdAt: now,
              updatedAt: now,
            )
          : open.copyWith(
              startsAt: startsAt.toUtc(),
              isTimeFixed: isTimeFixed,
              routePosition: const Optional.empty(),
              updatedAt: now,
            );
      await _appointments.upsert(booking);
      return booking;
    });
  }

  @override
  Future<void> setStatus(String id, AppointmentStatus status) {
    final now = _now();
    return _transaction.run(() async {
      final appointment = await _appointments.find(id);
      if (appointment == null || appointment.isDeleted) {
        throw AppointmentNotFoundException(id);
      }
      if (appointment.status != status) {
        await _appointments.upsert(appointment.copyWith(status: status, updatedAt: now));
      }
    });
  }

  /// The earliest planned appointment from local midnight today on.
  Appointment? _openBooking(List<Appointment> appointments) {
    final now = _now().toLocal();
    final from = DateTime(now.year, now.month, now.day).toUtc();
    final open = [
      for (final appointment in appointments)
        if (appointment.status == AppointmentStatus.planned &&
            !appointment.isDeleted &&
            !appointment.startsAt.isBefore(from))
          appointment,
    ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return open.firstOrNull;
  }
}
