import 'package:mocktail/mocktail.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:test/test.dart';

class MockTradesRepository() extends Mock implements TradesRepository;

class MockServiceTypesRepository() extends Mock implements ServiceTypesRepository;

final class FakeTransactionRunner() implements TransactionRunner {
  int runs = 0;

  @override
  Future<T> run<T>(Future<T> Function() action) {
    runs++;
    return action();
  }
}

void main() {
  final earlier = DateTime.utc(2026, 9, 2);
  final now = DateTime.utc(2026, 10, 6, 12);
  late MockTradesRepository trades;
  late MockServiceTypesRepository serviceTypes;
  late FakeTransactionRunner transaction;
  late CatalogServiceImpl service;

  List<Trade> upsertedTrades() => verify(() => trades.upsert(captureAny())).captured.cast<Trade>();
  List<ServiceType> upsertedTypes() =>
      verify(() => serviceTypes.upsert(captureAny())).captured.cast<ServiceType>();

  setUpAll(() {
    registerFallbackValue(Trade(id: '', name: '', createdAt: now, updatedAt: now));
    registerFallbackValue(
      ServiceType(id: '', name: '', cycleMonths: 1, createdAt: now, updatedAt: now),
    );
    registerFallbackValue(TradeTemplate.chimney);
    registerFallbackValue(ServiceTypeTemplate.chimneyInspection);
  });

  setUp(() {
    trades = MockTradesRepository();
    serviceTypes = MockServiceTypesRepository();
    transaction = FakeTransactionRunner();
    when(() => trades.find(any())).thenAnswer((_) async => null);
    when(() => trades.findByTemplate(any())).thenAnswer((_) async => null);
    when(() => serviceTypes.findByTemplate(any())).thenAnswer((_) async => null);
    when(() => trades.upsert(any())).thenAnswer((_) async {});
    when(() => serviceTypes.upsert(any())).thenAnswer((_) async {});
    service = CatalogServiceImpl(trades, serviceTypes, transaction, now: () => now);
  });

  group('copyDefaults', () {
    test('copies the picked trades and their service types in one transaction', () async {
      await service.copyDefaults([TradeTemplate.boiler, TradeTemplate.chimney]);

      expect(transaction.runs, 1);
      final copiedTrades = upsertedTrades();
      expect(copiedTrades.map((t) => (t.template, t.name, t.sortOrder)), [
        (TradeTemplate.chimney, null, 0),
        (TradeTemplate.boiler, null, 2),
      ]);
      expect(copiedTrades.map((t) => (t.createdAt, t.updatedAt)), everyElement((now, now)));

      final chimney = copiedTrades.first;
      final copiedTypes = upsertedTypes();
      expect(copiedTypes.map((s) => s.template), [
        ServiceTypeTemplate.chimneyInspection,
        ServiceTypeTemplate.chimneySweepSolid,
        ServiceTypeTemplate.chimneySweepGas,
        ServiceTypeTemplate.boilerService,
      ]);
      expect(copiedTypes[1].tradeId, chimney.id);
      expect(copiedTypes[1].name, isNull);
      expect(copiedTypes[1].cycleMonths, 3);
      expect(copiedTypes[1].sortOrder, 1);
      expect(copiedTypes.last.tradeId, copiedTrades.last.id);
      expect({...copiedTrades.map((t) => t.id), ...copiedTypes.map((s) => s.id)}, hasLength(6));
    });

    test('copies a trade picked twice once', () async {
      await service.copyDefaults([TradeTemplate.gas, TradeTemplate.gas]);

      expect(upsertedTrades(), hasLength(1));
      expect(upsertedTypes(), hasLength(1));
    });

    test('writes nothing when nothing is picked', () async {
      await service.copyDefaults([]);

      verifyNever(() => trades.upsert(any()));
      verifyNever(() => serviceTypes.upsert(any()));
    });

    test('keeps what the user has and copies only the missing templates', () async {
      final trade = Trade(
        id: 't1',
        name: 'Moje kominy',
        template: TradeTemplate.chimney,
        createdAt: earlier,
        updatedAt: earlier,
      );
      final inspection = ServiceType(
        id: 's1',
        tradeId: 't1',
        name: 'Przegląd',
        cycleMonths: 6,
        template: ServiceTypeTemplate.chimneyInspection,
        isArchived: true,
        createdAt: earlier,
        updatedAt: earlier,
      );
      when(() => trades.findByTemplate(TradeTemplate.chimney)).thenAnswer((_) async => trade);
      when(
        () => serviceTypes.findByTemplate(ServiceTypeTemplate.chimneyInspection),
      ).thenAnswer((_) async => inspection);

      await service.copyDefaults([TradeTemplate.chimney]);

      verifyNever(() => trades.upsert(any()));
      final copiedTypes = upsertedTypes();
      expect(copiedTypes.map((s) => s.template), [
        ServiceTypeTemplate.chimneySweepSolid,
        ServiceTypeTemplate.chimneySweepGas,
      ]);
      expect(copiedTypes.map((s) => s.tradeId), everyElement('t1'));
    });

    test('restores soft-deleted templates with the user values', () async {
      final trade = Trade(
        id: 't1',
        name: 'Gaz',
        template: TradeTemplate.gas,
        createdAt: earlier,
        updatedAt: earlier,
        deletedAt: earlier,
      );
      final check = ServiceType(
        id: 's1',
        name: 'Szczelność',
        cycleMonths: 24,
        template: ServiceTypeTemplate.gasInstallationCheck,
        createdAt: earlier,
        updatedAt: earlier,
        deletedAt: earlier,
      );
      when(() => trades.findByTemplate(TradeTemplate.gas)).thenAnswer((_) async => trade);
      when(
        () => serviceTypes.findByTemplate(ServiceTypeTemplate.gasInstallationCheck),
      ).thenAnswer((_) async => check);

      await service.copyDefaults([TradeTemplate.gas]);

      expect(upsertedTrades(), [
        trade.copyWith(updatedAt: now, deletedAt: const Optional.empty()),
      ]);
      expect(upsertedTypes(), [
        check.copyWith(
          tradeId: const Optional('t1'),
          updatedAt: now,
          deletedAt: const Optional.empty(),
        ),
      ]);
    });

    test('a restored type stays under a live trade and leaves a deleted one', () async {
      ServiceType deletedType(ServiceTypeTemplate template, String tradeId) => ServiceType(
        id: template.name,
        tradeId: tradeId,
        cycleMonths: 12,
        template: template,
        createdAt: earlier,
        updatedAt: earlier,
        deletedAt: earlier,
      );
      when(() => trades.find('mine')).thenAnswer(
        (_) async => Trade(id: 'mine', name: 'Moje', createdAt: earlier, updatedAt: earlier),
      );
      when(() => trades.find('gone')).thenAnswer(
        (_) async => Trade(
          id: 'gone',
          name: 'Stare',
          createdAt: earlier,
          updatedAt: earlier,
          deletedAt: earlier,
        ),
      );
      when(
        () => serviceTypes.findByTemplate(ServiceTypeTemplate.chimneyInspection),
      ).thenAnswer((_) async => deletedType(ServiceTypeTemplate.chimneyInspection, 'mine'));
      when(
        () => serviceTypes.findByTemplate(ServiceTypeTemplate.chimneySweepSolid),
      ).thenAnswer((_) async => deletedType(ServiceTypeTemplate.chimneySweepSolid, 'gone'));

      await service.copyDefaults([TradeTemplate.chimney]);

      final chimney = upsertedTrades().single;
      expect(upsertedTypes().take(2).map((s) => s.tradeId), ['mine', chimney.id]);
    });

    test('stops at the first failed write and rethrows it to roll back', () async {
      when(
        () => serviceTypes.upsert(
          any(that: isA<ServiceType>().having((s) => s.cycleMonths, 'cycleMonths', 3)),
        ),
      ).thenThrow(StateError('disk full'));

      await expectLater(
        service.copyDefaults([TradeTemplate.chimney, TradeTemplate.gas]),
        throwsStateError,
      );

      expect(upsertedTrades().map((t) => t.template), [TradeTemplate.chimney]);
      expect(upsertedTypes().map((s) => s.template), [
        ServiceTypeTemplate.chimneyInspection,
        ServiceTypeTemplate.chimneySweepSolid,
      ]);
    });
  });
}
