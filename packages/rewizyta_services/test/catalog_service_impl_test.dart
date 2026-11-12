import 'package:mocktail/mocktail.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:test/test.dart';

import 'helpers/mocks.dart';

void main() {
  final earlier = DateTime.utc(2026, 9, 2);
  final now = DateTime.utc(2026, 10, 6, 12);
  late MockTradesRepository trades;
  late MockServiceTypesRepository serviceTypes;
  late MockEquipmentRepository equipment;
  late MockVisitsRepository visits;
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
    registerFallbackValue(
      Equipment(id: '', clientId: '', serviceTypeId: '', createdAt: now, updatedAt: now),
    );
    registerFallbackValue(TradeTemplate.chimney);
    registerFallbackValue(ServiceTypeTemplate.chimneyInspection);
  });

  setUp(() {
    trades = MockTradesRepository();
    serviceTypes = MockServiceTypesRepository();
    equipment = MockEquipmentRepository();
    visits = MockVisitsRepository();
    transaction = FakeTransactionRunner();
    when(() => trades.find(any())).thenAnswer((_) async => null);
    when(() => trades.findByTemplate(any())).thenAnswer((_) async => null);
    when(() => serviceTypes.findByTemplate(any())).thenAnswer((_) async => null);
    when(() => trades.upsert(any())).thenAnswer((_) async {});
    when(() => serviceTypes.upsert(any())).thenAnswer((_) async {});
    when(() => equipment.upsert(any())).thenAnswer((_) async {});
    service = CatalogServiceImpl(
      trades,
      serviceTypes,
      equipment,
      visits,
      transaction,
      now: () => now,
    );
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
      // Unique across the trades, so a picker of all types has a stable order.
      expect(copiedTypes.map((s) => s.sortOrder), [0, 1, 2, 4]);
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

  group('addTrade', () {
    test('adds the trimmed custom name after the last trade', () async {
      when(trades.watchAll).thenAnswer(
        (_) => Stream.value([
          Trade(id: 't1', template: TradeTemplate.chimney, createdAt: earlier, updatedAt: earlier),
          Trade(id: 't2', name: 'Moje', sortOrder: 4, createdAt: earlier, updatedAt: earlier),
        ]),
      );

      await service.addTrade('  Wentylacja ');

      final added = upsertedTrades().single;
      expect((added.name, added.template, added.sortOrder), ('Wentylacja', null, 5));
      expect((added.createdAt, added.updatedAt), (now, now));
      expect(added.id, isNotEmpty);
    });

    test('a trade added to an empty catalogue leaves room for the defaults', () async {
      when(trades.watchAll).thenAnswer((_) => Stream.value(const []));

      await service.addTrade('Wentylacja');

      // copyDefaults puts the defaults at their template index, so restored
      // later they still come first.
      expect(upsertedTrades().single.sortOrder, TradeTemplate.values.length);
    });

    test('rejects a blank name and writes nothing', () async {
      await expectLater(
        service.addTrade('   '),
        throwsA(
          isA<TradeValidationException>().having(
            (e) => e.error,
            'error',
            TradeValidationError.nameEmpty,
          ),
        ),
      );

      verifyNever(() => trades.upsert(any()));
    });
  });

  group('saveServiceType', () {
    final type = ServiceType(
      id: 'st',
      tradeId: 't1',
      name: 'Przegląd',
      cycleMonths: 12,
      createdAt: earlier,
      updatedAt: earlier,
    );
    final boiler = ServiceType(
      id: 'boiler',
      tradeId: 't1',
      cycleMonths: 12,
      template: ServiceTypeTemplate.boilerService,
      sortOrder: 4,
      createdAt: earlier,
      updatedAt: earlier,
    );
    Equipment item(String id, {DateTime? lastVisitAt, DateTime? nextDueAt}) => Equipment(
      id: id,
      clientId: 'c',
      serviceTypeId: 'st',
      lastVisitAt: lastVisitAt,
      nextDueAt: nextDueAt,
      createdAt: earlier,
      updatedAt: earlier,
    );
    Matcher validation(ServiceTypeValidationError error) =>
        throwsA(isA<ServiceTypeValidationException>().having((e) => e.error, 'error', error));

    setUp(() {
      when(() => serviceTypes.find('st')).thenAnswer((_) async => type);
      when(() => serviceTypes.find('boiler')).thenAnswer((_) async => boiler);
      when(serviceTypes.watchAll).thenAnswer((_) => Stream.value([boiler, type]));
    });

    test('adds a new type under the trade after the last one', () async {
      await service.saveServiceType(
        tradeId: 't2',
        name: ' Przegląd wentylacji ',
        cycleMonths: 24,
        defaultPriceGrosze: 25000,
        isArchived: true,
      );

      final added = upsertedTypes().single;
      expect(
        (added.tradeId, added.name, added.template, added.cycleMonths, added.sortOrder),
        ('t2', 'Przegląd wentylacji', null, 24, 5),
      );
      expect((added.defaultPriceGrosze, added.isArchived), (25000, true));
      expect((added.createdAt, added.updatedAt), (now, now));
      verifyNever(() => equipment.findByServiceType(any()));
    });

    test('a type added to an empty catalogue leaves room for the defaults', () async {
      when(serviceTypes.watchAll).thenAnswer((_) => Stream.value(const []));

      await service.saveServiceType(tradeId: 't2', name: 'Wentylacja', cycleMonths: 12);

      expect(upsertedTypes().single.sortOrder, ServiceTypeTemplate.values.length);
    });

    test('a new type needs a name', () async {
      await expectLater(
        service.saveServiceType(tradeId: 't1', name: ' ', cycleMonths: 12),
        validation(ServiceTypeValidationError.nameEmpty),
      );

      verifyNever(() => serviceTypes.upsert(any()));
    });

    test('rejects a cycle below one month before reading anything', () async {
      await expectLater(
        service.saveServiceType(id: 'st', tradeId: 't1', name: 'Przegląd', cycleMonths: 0),
        validation(ServiceTypeValidationError.cycleBelowOne),
      );

      expect(transaction.runs, 0);
      verifyNever(() => serviceTypes.find(any()));
    });

    test('accepts a ten-year cycle and rejects a longer one', () async {
      when(() => equipment.findByServiceType('st')).thenAnswer((_) async => []);

      await service.saveServiceType(
        id: 'st',
        tradeId: 't1',
        name: 'Przegląd',
        cycleMonths: ServiceType.maxCycleMonths,
      );
      await expectLater(
        service.saveServiceType(
          tradeId: 't1',
          name: 'Przegląd',
          cycleMonths: ServiceType.maxCycleMonths + 1,
        ),
        validation(ServiceTypeValidationError.cycleTooLong),
      );

      expect(upsertedTypes().single.cycleMonths, 120);
    });

    test('renames, prices and archives without touching the due dates', () async {
      await service.saveServiceType(
        id: 'st',
        tradeId: 't1',
        name: ' Kocioł ',
        cycleMonths: 12,
        defaultPriceGrosze: 18050,
        isArchived: true,
      );

      expect(transaction.runs, 1);
      expect(
        upsertedTypes().single,
        type.copyWith(
          name: const Optional('Kocioł'),
          defaultPriceGrosze: const Optional(18050),
          isArchived: true,
          updatedAt: now,
        ),
      );
      verifyNever(() => equipment.findByServiceType(any()));
    });

    test('a blank name on a default brings its localized name back', () async {
      when(
        () => serviceTypes.find('boiler'),
      ).thenAnswer((_) async => boiler.copyWith(name: const Optional('Kocioł')));

      await service.saveServiceType(id: 'boiler', tradeId: 't1', name: '', cycleMonths: 12);

      expect(upsertedTypes().single, boiler.copyWith(updatedAt: now));
    });

    test('a type without a default keeps a name', () async {
      await expectLater(
        service.saveServiceType(id: 'st', tradeId: 't1', name: '  ', cycleMonths: 12),
        validation(ServiceTypeValidationError.nameEmpty),
      );

      verifyNever(() => serviceTypes.upsert(any()));
    });

    test('a new cycle moves the due dates of its equipment in one transaction', () async {
      final visited = item(
        'visited',
        lastVisitAt: DateTime.utc(2026, 1, 31),
        nextDueAt: DateTime.utc(2027, 1, 31),
      );
      final never = item('never');
      when(() => equipment.findByServiceType('st')).thenAnswer((_) async => [visited, never]);
      when(() => visits.lastDoneAt('visited')).thenAnswer((_) async => DateTime.utc(2026, 1, 31));
      when(() => visits.lastDoneAt('never')).thenAnswer((_) async => null);

      await service.saveServiceType(id: 'st', tradeId: 't1', name: 'Przegląd', cycleMonths: 1);

      expect(transaction.runs, 1);
      expect(upsertedTypes().single, type.copyWith(cycleMonths: 1, updatedAt: now));
      final saved = verify(() => equipment.upsert(captureAny())).captured.cast<Equipment>();
      expect(saved.single.id, 'visited');
      expect(saved.single.nextDueAt, DateTime.utc(2026, 2, 28));
      expect(saved.single.updatedAt, now);
    });

    test('writes nothing when nothing changed', () async {
      await service.saveServiceType(id: 'st', tradeId: 't1', name: 'Przegląd', cycleMonths: 12);

      verifyNever(() => serviceTypes.upsert(any()));
      verifyNever(() => equipment.findByServiceType(any()));
    });

    test('throws for an unknown service type', () async {
      when(() => serviceTypes.find('x')).thenAnswer((_) async => null);

      await expectLater(
        service.saveServiceType(id: 'x', tradeId: 't1', name: 'X', cycleMonths: 6),
        throwsA(isA<ServiceTypeNotFoundException>()),
      );
    });
  });

  test('watchTrades passes through to the repository', () async {
    final trade = Trade(id: 't', name: 'Mine', createdAt: now, updatedAt: now);
    when(trades.watchAll).thenAnswer((_) => Stream.value([trade]));

    expect(await service.watchTrades().first, [trade]);
  });

  test('watchServiceTypes passes through to the repository', () async {
    final type = ServiceType(id: 's', name: 'Mine', cycleMonths: 6, createdAt: now, updatedAt: now);
    when(serviceTypes.watchAll).thenAnswer((_) => Stream.value([type]));

    expect(await service.watchServiceTypes().first, [type]);
  });

  group('ensureDefaults', () {
    test('copies the whole catalogue when the user has no service type', () async {
      when(serviceTypes.watchAll).thenAnswer((_) => Stream.value(const []));

      await service.ensureDefaults();

      expect(upsertedTrades().map((t) => t.template), TradeTemplate.values);
    });

    test('leaves an existing catalogue alone', () async {
      when(serviceTypes.watchAll).thenAnswer(
        (_) => Stream.value([
          ServiceType(id: 's', name: 'Mine', cycleMonths: 6, createdAt: now, updatedAt: now),
        ]),
      );

      await service.ensureDefaults();

      verifyNever(() => trades.upsert(any()));
      verifyNever(() => serviceTypes.upsert(any()));
    });
  });
}
