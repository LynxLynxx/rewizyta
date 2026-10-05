import 'package:rewizyta_models/rewizyta_models.dart';

/// Equipment at the clients, with the outbox rows for it.
abstract interface class EquipmentRepository() {
  /// The client's live equipment in the order it was added.
  Stream<List<Equipment>> watchByClient(String clientId);

  /// Any equipment by id, soft-deleted included.
  Future<Equipment?> find(String id);

  /// Live equipment of one service type, whose due dates follow its cycle.
  Future<List<Equipment>> findByServiceType(String serviceTypeId);

  /// Upserts the row and queues it for the push in one transaction.
  Future<void> upsert(Equipment equipment);
}
