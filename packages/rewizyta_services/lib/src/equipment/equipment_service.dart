import 'package:rewizyta_models/rewizyta_models.dart';

/// Equipment at the clients.
abstract interface class EquipmentService() {
  /// All live equipment, for the status of every client on the list.
  Stream<List<Equipment>> watchAll();

  /// The client's live equipment in the order it was added; with
  /// [includeDeleted], the soft-deleted rows too, which the visit history
  /// still names.
  Stream<List<Equipment>> watchByClient(String clientId, {bool includeDeleted = false});

  /// The client's live equipment once.
  Future<List<Equipment>> findByClient(String clientId);

  /// Adds (no [id]) or updates equipment at a client. The due dates are
  /// recomputed from the visit history and the cycle of [serviceTypeId], so a
  /// new service type moves them. Throws [EquipmentNotFoundException] or
  /// [ServiceTypeNotFoundException] for an unknown id and
  /// [EquipmentValidationException] when [count] is below 1.
  Future<Equipment> saveEquipment({
    String? id,
    required String clientId,
    required String serviceTypeId,
    String? label,
    int count = 1,
    String? note,
  });

  /// Soft-deletes the equipment; its visit history stays. Throws
  /// [EquipmentNotFoundException] for an unknown [id].
  Future<void> deleteEquipment(String id);
}
