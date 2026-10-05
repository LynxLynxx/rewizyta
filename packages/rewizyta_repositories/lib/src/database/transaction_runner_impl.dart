import 'package:rewizyta_repositories/src/database/app_database.dart';
import 'package:rewizyta_repositories/src/database/transaction_runner.dart';

/// Drift nests the repositories' own transactions inside this one.
final class const TransactionRunnerImpl(final AppDatabase _db) implements TransactionRunner {
  @override
  Future<T> run<T>(Future<T> Function() action) => _db.transaction(action);
}
