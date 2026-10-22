import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:rewizyta_services/src/common/clean_text.dart';
import 'package:rewizyta_services/src/due/due_date_updater.dart';
import 'package:rewizyta_services/src/equipment/equipment_service.dart';
import 'package:uuid/uuid.dart';

final class EquipmentServiceImpl(
  final EquipmentRepository _equipment,
  final ServiceTypesRepository _serviceTypes,
  VisitsRepository visits,
  final TransactionRunner _transaction, {
  DateTime Function()? now,
  Uuid? uuid,
}) implements EquipmentService {
  final DueDateUpdater _due = DueDateUpdater(visits, _equipment, _serviceTypes);
  final DateTime Function() _now = now ?? DateTime.timestamp;
  final Uuid _uuid = uuid ?? const Uuid();

  @override
  Future<Equipment> saveEquipment({
    String? id,
    required String clientId,
    required String serviceTypeId,
    String? label,
    int count = 1,
    String? note,
  }) {
    if (count < 1) {
      throw const EquipmentValidationException(EquipmentValidationError.countBelowOne);
    }
    final now = _now();
    return _transaction.run(() async {
      final serviceType = await _serviceTypes.find(serviceTypeId);
      if (serviceType == null) {
        throw ServiceTypeNotFoundException(serviceTypeId);
      }
      final existing = id == null ? null : await _equipment.find(id);
      if (id != null && existing == null) {
        throw EquipmentNotFoundException(id);
      }
      final equipment = Equipment(
        id: existing?.id ?? _uuid.v4(),
        clientId: clientId,
        serviceTypeId: serviceTypeId,
        label: cleanText(label),
        count: count,
        note: cleanText(note),
        lastVisitAt: existing?.lastVisitAt,
        nextDueAt: existing?.nextDueAt,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      final saved = await _due.recompute(equipment, serviceType.cycleMonths, now);
      await _equipment.upsert(saved);
      return saved;
    });
  }
}
