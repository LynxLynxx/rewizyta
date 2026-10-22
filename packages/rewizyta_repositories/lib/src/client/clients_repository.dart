import 'package:rewizyta_models/rewizyta_models.dart';

/// Local store of clients. The phone is the source of truth, so this
/// repository owns the drift table and the outbox rows for it.
abstract interface class ClientsRepository() {
  /// Live, non-deleted clients in no particular order (the service sorts them
  /// in Polish order). Emits on every local change, including ones applied
  /// by a sync pull.
  Stream<List<Client>> watchAll();

  /// One client, deleted or not; null while the id is unknown.
  Stream<Client?> watch(String id);

  Future<Client?> find(String id);

  /// Upserts the row and appends an outbox entry in one transaction.
  Future<void> upsert(Client client);
}
