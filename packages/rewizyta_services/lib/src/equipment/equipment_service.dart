import 'package:rewizyta_models/rewizyta_models.dart';

/// Equipment at the clients.
abstract interface class EquipmentService() {
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
}
