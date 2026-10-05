import 'package:rewizyta_models/rewizyta_models.dart';

/// The user's service types and their cycles, with the outbox rows for them.
abstract interface class ServiceTypesRepository() {
  /// Live service types, archived ones included, in the user's order.
  Stream<List<ServiceType>> watchAll();

  /// Any service type by id, soft-deleted ones included.
  Future<ServiceType?> find(String id);

  /// The type copied from the default [templateKey], soft-deleted or not.
  Future<ServiceType?> findByTemplateKey(String templateKey);

  /// Upserts the row and queues it for the push in one transaction.
  Future<void> upsert(ServiceType serviceType);
}
