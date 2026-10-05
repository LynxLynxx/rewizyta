import 'package:rewizyta_models/rewizyta_models.dart';

/// This phone's push registration, with the outbox rows for it.
abstract interface class DevicesRepository() {
  Future<Device?> find(String id);

  /// Upserts the row and queues it for the push in one transaction.
  Future<void> upsert(Device device);
}
