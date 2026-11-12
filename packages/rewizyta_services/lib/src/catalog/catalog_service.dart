import 'package:rewizyta_models/rewizyta_models.dart';

/// The user's trades and service types, seeded from the default catalogue
/// ([TradeTemplate], [ServiceTypeTemplate]).
abstract interface class CatalogService() {
  /// Live trades, archived ones included, in the user's order.
  Stream<List<Trade>> watchTrades();

  /// Live service types, archived ones included, in the user's order.
  Stream<List<ServiceType>> watchServiceTypes();

  /// Adds a trade of the user's own after the others. Throws
  /// [TradeValidationException] when [name] is blank.
  Future<void> addTrade(String name);

  /// Adds a service type under [tradeId] after the others, or with [id]
  /// edits that one. A changed cycle moves the due dates of all its equipment
  /// in the same transaction. A blank [name] on a default brings its
  /// localized name back. Throws [ServiceTypeValidationException] when
  /// [cycleMonths] is outside 1 to [ServiceType.maxCycleMonths] or a type
  /// without a default has no name, and
  /// [ServiceTypeNotFoundException] for an unknown [id].
  Future<void> saveServiceType({
    String? id,
    required String tradeId,
    required String name,
    required int cycleMonths,
    int? defaultPriceGrosze,
    bool isArchived = false,
  });

  /// Copies the whole default catalogue when the user has no service type yet.
  /// Stands in for onboarding's trade picker until that lands (M7), which
  /// replaces the only call to it.
  Future<void> ensureDefaults();

  /// Copies [trades] and their service types into the user's rows, in one
  /// transaction, without a name (the UI localizes the template until the
  /// user renames it). Used by onboarding and by "restore defaults": a
  /// template the user already has is left as it is, a soft-deleted one is
  /// restored with the user's values, and only a missing one is copied.
  Future<void> copyDefaults(Iterable<TradeTemplate> trades);
}
