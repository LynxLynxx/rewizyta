import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';

/// Keeps the cached `lastVisitAt` / `nextDueAt` on equipment in step with the
/// visit history and the service type's cycle (docs/BACKEND_SCHEMA.md, "Due
/// dates"). Shared by the services that write visits, equipment and cycles,
/// which call it inside their transaction. Saves only what changed, so an
/// unchanged item queues no outbox entry.
final class const DueDateUpdater(
  final VisitsRepository _visits,
  final EquipmentRepository _equipment,
  final ServiceTypesRepository _serviceTypes,
) {
  /// [equipment] with its caches recomputed for [cycleMonths], or [equipment]
  /// itself when they are current. Does not save.
  Future<Equipment> recompute(Equipment equipment, int cycleMonths, DateTime now) async {
    final lastVisitAt = await _visits.lastDoneAt(equipment.id);
    final nextDueAt = lastVisitAt == null ? null : nextDue(lastVisitAt, cycleMonths);
    if (lastVisitAt == equipment.lastVisitAt && nextDueAt == equipment.nextDueAt) {
      return equipment;
    }
    return equipment.withDue(lastVisitAt: lastVisitAt, nextDueAt: nextDueAt, updatedAt: now);
  }

  /// Recomputes the live equipment with these ids (after a visit or its items
  /// changed) and saves what changed.
  Future<void> updateEquipment(Iterable<String> equipmentIds, DateTime now) async {
    for (final id in equipmentIds) {
      final equipment = await _equipment.find(id);
      if (equipment == null || equipment.isDeleted) {
        continue;
      }
      final serviceType = await _serviceTypes.find(equipment.serviceTypeId);
      if (serviceType == null) {
        throw ServiceTypeNotFoundException(equipment.serviceTypeId);
      }
      await _save(equipment, await recompute(equipment, serviceType.cycleMonths, now));
    }
  }

  /// Recomputes every live equipment of [serviceType] (after its cycle
  /// changed) and saves what changed.
  Future<void> updateServiceType(ServiceType serviceType, DateTime now) async {
    for (final equipment in await _equipment.findByServiceType(serviceType.id)) {
      await _save(equipment, await recompute(equipment, serviceType.cycleMonths, now));
    }
  }

  Future<void> _save(Equipment before, Equipment after) async {
    if (after != before) {
      await _equipment.upsert(after);
    }
  }
}
