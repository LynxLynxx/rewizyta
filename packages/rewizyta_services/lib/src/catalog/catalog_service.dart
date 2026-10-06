import 'package:rewizyta_models/rewizyta_models.dart';

/// The user's trades and service types, seeded from the default catalogue
/// ([TradeTemplate], [ServiceTypeTemplate]).
abstract interface class CatalogService() {
  /// Copies [trades] and their service types into the user's rows, in one
  /// transaction, without a name (the UI localizes the template until the
  /// user renames it). Used by onboarding and by "restore defaults": a
  /// template the user already has is left as it is, a soft-deleted one is
  /// restored with the user's values, and only a missing one is copied.
  Future<void> copyDefaults(Iterable<TradeTemplate> trades);
}
