import 'package:rewizyta_models/rewizyta_models.dart';

/// Visits, with the outbox rows for them. What a visit serviced is in
/// `VisitItemsRepository`.
abstract interface class VisitsRepository() {
  /// The client's live visits, newest first.
  Stream<List<Visit>> watchByClient(String clientId);

  /// Any visit by id, soft-deleted included.
  Future<Visit?> find(String id);

  /// The day of the latest live visit with a live item for [equipmentId], or
  /// null if there is none. The input of the due-date rule.
  Future<DateTime?> lastDoneAt(String equipmentId);

  /// Upserts the row and queues it for the push in one transaction.
  Future<void> upsert(Visit visit);
}
