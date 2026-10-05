import 'package:rewizyta_models/rewizyta_models.dart';

/// The user's trades (branże), with the outbox rows for them.
abstract interface class TradesRepository() {
  /// Live trades, archived ones included, in the user's order.
  Stream<List<Trade>> watchAll();

  /// Any trade by id, soft-deleted ones included.
  Future<Trade?> find(String id);

  /// The trade copied from the default [templateKey], soft-deleted or not, so
  /// "restore defaults" can bring it back instead of copying it twice.
  Future<Trade?> findByTemplateKey(String templateKey);

  /// Upserts the row and queues it for the push in one transaction.
  Future<void> upsert(Trade trade);
}
