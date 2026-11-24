import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:rewizyta_services/src/common/clean_text.dart';
import 'package:rewizyta_services/src/due/due_date_updater.dart';
import 'package:rewizyta_services/src/visit/visits_service.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:uuid/uuid.dart';

final class VisitsServiceImpl(
  final VisitsRepository _visits,
  final VisitItemsRepository _visitItems,
  EquipmentRepository equipment,
  ServiceTypesRepository serviceTypes,
  final AppointmentsRepository _appointments,
  final TransactionRunner _transaction, {
  DateTime Function()? now,
  Uuid? uuid,
}) implements VisitsService {
  final DueDateUpdater _due = DueDateUpdater(_visits, equipment, serviceTypes);
  final DateTime Function() _now = now ?? DateTime.timestamp;
  final Uuid _uuid = uuid ?? const Uuid();

  @override
  Stream<List<Visit>> watchByClient(String clientId) => _visits.watchByClient(clientId);

  @override
  Stream<List<VisitItem>> watchItemsByClient(String clientId) =>
      _visitItems.watchByClient(clientId);

  @override
  Future<Visit> getVisit(String id) => _find(id);

  @override
  Future<List<VisitItem>> findItems(String visitId) async {
    final items = await _visitItems.findByVisit(visitId);
    return [
      for (final item in items)
        if (!item.isDeleted) item,
    ];
  }

  @override
  Future<Visit> saveVisit({
    String? id,
    required String clientId,
    required DateTime doneAt,
    required Set<String> equipmentIds,
    int? priceGrosze,
    String? note,
    String? appointmentId,
  }) {
    if (priceGrosze != null && priceGrosze < 0) {
      throw const VisitValidationException(VisitValidationError.priceNegative);
    }
    final now = _now();
    return _transaction.run(() async {
      final existing = id == null ? null : await _find(id);
      final booking = await _bookingOf(
        clientId: clientId,
        doneAt: doneAt,
        appointmentId: appointmentId,
        isNew: existing == null,
      );
      final visit = Visit(
        id: existing?.id ?? _uuid.v4(),
        clientId: clientId,
        doneAt: DateTime.utc(doneAt.year, doneAt.month, doneAt.day),
        priceGrosze: priceGrosze,
        note: cleanText(note),
        appointmentId: appointmentId ?? booking?.id,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      await _visits.upsert(visit);
      if (booking != null) {
        await _setBookingStatus(booking, AppointmentStatus.done, now);
      }

      final items = existing == null
          ? const <VisitItem>[]
          : await _visitItems.findByVisit(visit.id);
      for (final item in items) {
        final ticked = equipmentIds.contains(item.equipmentId);
        if (ticked == item.isDeleted) {
          await _visitItems.upsert(
            item.copyWith(
              updatedAt: now,
              deletedAt: ticked ? const Optional.empty() : Optional(now),
            ),
          );
        }
      }
      final itemized = {for (final item in items) item.equipmentId};
      for (final equipmentId in equipmentIds.difference(itemized)) {
        await _visitItems.upsert(
          VisitItem(
            id: _uuid.v4(),
            visitId: visit.id,
            equipmentId: equipmentId,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      await _due.updateEquipment({...itemized, ...equipmentIds}, now);
      return visit;
    });
  }

  @override
  Future<void> deleteVisit(String id) => _setDeleted(id, deleted: true);

  @override
  Future<void> restoreVisit(String id) => _setDeleted(id, deleted: false);

  /// Deletes or restores the visit and recomputes the due dates of what it
  /// serviced.
  Future<void> _setDeleted(String id, {required bool deleted}) {
    final now = _now();
    return _transaction.run(() async {
      final visit = await _find(id);
      await _visits.upsert(
        visit.copyWith(
          updatedAt: now,
          deletedAt: deleted ? Optional(now) : const Optional.empty(),
        ),
      );
      final items = await _visitItems.findByVisit(id);
      await _due.updateEquipment(items.map((item) => item.equipmentId), now);
      final bookingId = visit.appointmentId;
      final booking = bookingId == null ? null : await _appointments.find(bookingId);
      if (booking != null) {
        await _setBookingStatus(
          booking,
          deleted ? AppointmentStatus.planned : AppointmentStatus.done,
          now,
        );
      }
    });
  }

  /// The booking a visit fulfils: the one it names, or for a new visit the
  /// client's earliest planned appointment on the visit's day, so a visit
  /// recorded from the card does not leave its booking open.
  Future<Appointment?> _bookingOf({
    required String clientId,
    required DateTime doneAt,
    required String? appointmentId,
    required bool isNew,
  }) async {
    if (appointmentId != null) {
      return await _appointments.find(appointmentId);
    }
    if (!isNew) {
      return null;
    }
    final sameDay = [
      for (final appointment in await _appointments.findByClient(clientId))
        if (appointment.status == AppointmentStatus.planned &&
            _isOn(appointment.startsAt.toLocal(), doneAt))
          appointment,
    ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return sameDay.firstOrNull;
  }

  bool _isOn(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// A recorded visit marks its planned booking done; deleting the visit puts
  /// a done one back to planned. Any other status (cancelled, no-show) is the
  /// technician's own word and stays.
  Future<void> _setBookingStatus(Appointment booking, AppointmentStatus to, DateTime now) async {
    final from = to == AppointmentStatus.done ? AppointmentStatus.planned : AppointmentStatus.done;
    if (booking.isDeleted || booking.status != from) {
      return;
    }
    await _appointments.upsert(booking.copyWith(status: to, updatedAt: now));
  }

  Future<Visit> _find(String id) async {
    final visit = await _visits.find(id);
    if (visit == null) {
      throw VisitNotFoundException(id);
    }
    return visit;
  }
}
