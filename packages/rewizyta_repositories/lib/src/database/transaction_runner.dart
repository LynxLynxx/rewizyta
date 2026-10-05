/// Runs several repository writes as one local transaction, so services can
/// keep a row and the values derived from it consistent (a visit and the
/// equipment's due dates) without importing drift.
abstract interface class TransactionRunner() {
  /// Runs [action] in one transaction: every write inside it, the outbox
  /// entries included, commits together or not at all. Repository calls
  /// inside join it.
  Future<T> run<T>(Future<T> Function() action);
}
