import 'package:rewizyta_models/rewizyta_models.dart';

/// What each visit serviced, with the outbox rows for it.
abstract interface class VisitItemsRepository() {
  /// Every item of the visit, soft-deleted ones included: a visit holds one
  /// row per equipment, so re-ticking an item must restore its old row.
  Future<List<VisitItem>> findByVisit(String visitId);

  /// Upserts the row and queues it for the push in one transaction.
  Future<void> upsert(VisitItem item);
}
