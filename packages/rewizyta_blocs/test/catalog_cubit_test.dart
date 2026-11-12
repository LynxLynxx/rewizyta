import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

class MockCatalogService() extends Mock implements CatalogService;

void main() {
  final now = DateTime.utc(2026);
  final chimney = Trade(id: 't1', template: TradeTemplate.chimney, createdAt: now, updatedAt: now);
  final vent = Trade(id: 't2', name: 'Wentylacja', sortOrder: 3, createdAt: now, updatedAt: now);
  ServiceType type(String id, String tradeId) => ServiceType(
    id: id,
    tradeId: tradeId,
    name: id,
    cycleMonths: 12,
    createdAt: now,
    updatedAt: now,
  );

  late MockCatalogService catalogService;
  late StreamController<List<Trade>> trades;
  late StreamController<List<ServiceType>> serviceTypes;

  CatalogCubit build() => CatalogCubit(catalogService);

  setUp(() {
    catalogService = MockCatalogService();
    // Broadcast: a single-subscription controller's close() never completes
    // without a listener, which would hang tearDown.
    trades = StreamController<List<Trade>>.broadcast();
    serviceTypes = StreamController<List<ServiceType>>.broadcast();
    when(catalogService.watchTrades).thenAnswer((_) => trades.stream);
    when(catalogService.watchServiceTypes).thenAnswer((_) => serviceTypes.stream);
  });

  tearDown(() async {
    await trades.close();
    await serviceTypes.close();
  });

  test('initial state is loading', () {
    final cubit = build();
    expect(cubit.state, const CatalogState());
    expect(cubit.state.isEmpty, isFalse);
    unawaited(cubit.close());
  });

  blocTest<CatalogCubit, CatalogState>(
    'waits for both streams, then groups the types under their trades',
    build: build,
    act: (cubit) async {
      cubit.init();
      trades.add([chimney, vent]);
      await Future<void>.delayed(Duration.zero);
      serviceTypes.add([type('a', 't1'), type('b', 't2'), type('c', 't1')]);
    },
    expect: () => [
      isA<CatalogState>()
          .having((s) => s.isLoading, 'isLoading', isFalse)
          .having((s) => s.trades.map((t) => t.id), 'trades', ['t1', 't2'])
          .having(
            (s) => s.trades.map((t) => t.serviceTypes.map((type) => type.id).toList()),
            'serviceTypes',
            [
              ['a', 'c'],
              ['b'],
            ],
          ),
    ],
  );

  blocTest<CatalogCubit, CatalogState>(
    'is empty without trades',
    build: build,
    act: (cubit) {
      cubit.init();
      trades.add(const []);
      serviceTypes.add(const []);
    },
    expect: () => [const CatalogState(isLoading: false)],
    verify: (cubit) {
      expect(cubit.state.isEmpty, isTrue);
      verifyNever(catalogService.ensureDefaults);
    },
  );

  test('a failing stream stops the spinner and goes to the error channel', () async {
    final cubit = build();
    final errors = <Object>[];
    final sub = cubit.errorStream.listen(errors.add);

    cubit.init();
    trades.addError(const ServiceTypeNotFoundException('x'));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, const CatalogState(isLoading: false));
    expect(errors.single, isA<LocalizedServiceTypeNotFoundException>());
    await sub.cancel();
    await cubit.close();
  });

  test('addTrade passes the name to the service', () async {
    when(() => catalogService.addTrade('Wentylacja')).thenAnswer((_) async {});
    final cubit = build();

    await cubit.addTrade('Wentylacja');

    verify(() => catalogService.addTrade('Wentylacja')).called(1);
    await cubit.close();
  });

  test('a failing addTrade goes to the error channel', () async {
    when(
      () => catalogService.addTrade(any()),
    ).thenThrow(const TradeValidationException(TradeValidationError.nameEmpty));
    final cubit = build();
    final errors = <Object>[];
    final sub = cubit.errorStream.listen(errors.add);

    await cubit.addTrade(' ');
    await Future<void>.delayed(Duration.zero);

    expect(errors.single, isA<LocalizedException>());
    await sub.cancel();
    await cubit.close();
  });

  test('restoreDefaults copies the whole default catalogue and signals', () async {
    when(() => catalogService.copyDefaults(TradeTemplate.values)).thenAnswer((_) async {});
    final cubit = build();
    final signals = <CatalogSignal>[];
    final sub = cubit.signalStream.listen(signals.add);

    await cubit.restoreDefaults();
    await Future<void>.delayed(Duration.zero);

    verify(() => catalogService.copyDefaults(TradeTemplate.values)).called(1);
    expect(signals, [CatalogSignal.defaultsRestored]);
    await sub.cancel();
    await cubit.close();
  });

  test('a failing restore goes to the error channel and does not signal', () async {
    when(
      () => catalogService.copyDefaults(TradeTemplate.values),
    ).thenThrow(const ServiceTypeNotFoundException('x'));
    final cubit = build();
    final errors = <Object>[];
    final signals = <CatalogSignal>[];
    final errorSub = cubit.errorStream.listen(errors.add);
    final signalSub = cubit.signalStream.listen(signals.add);

    await cubit.restoreDefaults();
    await Future<void>.delayed(Duration.zero);

    expect(errors.single, isA<LocalizedServiceTypeNotFoundException>());
    expect(signals, isEmpty);
    await errorSub.cancel();
    await signalSub.cancel();
    await cubit.close();
  });

  test('close cancels the subscriptions', () async {
    final cubit = build()..init();
    await cubit.close();
    expect(trades.hasListener, isFalse);
    expect(serviceTypes.hasListener, isFalse);
  });
}
