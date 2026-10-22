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
  final TransactionRunner _transaction, {
  DateTime Function()? now,
  Uuid? uuid,
}) implements VisitsService {
  final DueDateUpdater _due = DueDateUpdater(_visits, equipment, serviceTypes);
  final DateTime Function() _now = now ?? DateTime.timestamp;
  final Uuid _uuid = uuid ?? const Uuid();

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
      final visit = Visit(
        id: existing?.id ?? _uuid.v4(),
        clientId: clientId,
        doneAt: DateTime.utc(doneAt.year, doneAt.month, doneAt.day),
        priceGrosze: priceGrosze,
        note: cleanText(note),
        appointmentId: appointmentId,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      await _visits.upsert(visit);

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
  Future<void> deleteVisit(String id) {
    final now = _now();
    return _transaction.run(() async {
      final visit = await _find(id);
      await _visits.upsert(visit.copyWith(updatedAt: now, deletedAt: Optional(now)));
      final items = await _visitItems.findByVisit(id);
      await _due.updateEquipment(items.map((item) => item.equipmentId), now);
    });
  }

  Future<Visit> _find(String id) async {
    final visit = await _visits.find(id);
    if (visit == null) {
      throw VisitNotFoundException(id);
    }
    return visit;
  }
}
