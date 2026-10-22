import 'package:mocktail/mocktail.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';

class MockTradesRepository() extends Mock implements TradesRepository;

class MockServiceTypesRepository() extends Mock implements ServiceTypesRepository;

class MockEquipmentRepository() extends Mock implements EquipmentRepository;

class MockVisitsRepository() extends Mock implements VisitsRepository;

class MockVisitItemsRepository() extends Mock implements VisitItemsRepository;

/// Runs the action directly and counts the transactions.
final class FakeTransactionRunner() implements TransactionRunner {
  int runs = 0;

  @override
  Future<T> run<T>(Future<T> Function() action) {
    runs++;
    return action();
  }
}
