import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

class MockCatalogService() extends Mock implements CatalogService;

void main() {
  const boiler = ServiceTypeViewModel(
    id: 's1',
    cycleMonths: 12,
    template: ServiceTypeTemplate.boilerService,
    defaultPriceGrosze: 18050,
  );
  const custom = ServiceTypeViewModel(id: 's2', cycleMonths: 6, name: 'Wentylacja');

  late MockCatalogService catalogService;

  ServiceTypeFormCubit build() => ServiceTypeFormCubit(catalogService);

  setUp(() => catalogService = MockCatalogService());

  test('a new type starts on a 12-month cycle and needs a name', () async {
    final cubit = build()..init(tradeId: 't1');

    expect(
      cubit.state,
      const ServiceTypeFormState(cycle: '12'),
    );
    expect(cubit.state.canSave, isFalse);
    cubit.update(name: 'Przegląd wentylacji');
    expect(cubit.state.canSave, isTrue);
    await cubit.close();
  });

  test('a default starts with an empty name, its template and the formatted price', () async {
    final cubit = build()..init(tradeId: 't1', type: boiler);

    expect(
      cubit.state,
      const ServiceTypeFormState(
        isEditing: true,
        template: ServiceTypeTemplate.boilerService,
        cycle: '12',
        price: '180,50',
      ),
    );
    expect(cubit.state.canSave, isTrue);
    await cubit.close();
  });

  test('a cycle that is not whole months from 1 to 120 or a bad price blocks the save', () async {
    final cubit = build()..init(tradeId: 't1', type: custom);

    for (final cycle in ['', '0', 'x', '-3', '1,5', '121', '99999999999999999999']) {
      cubit.update(cycle: cycle);
      expect(cubit.state.isCycleInvalid, isTrue, reason: cycle);
      expect(cubit.state.canSave, isFalse, reason: cycle);
    }
    cubit.update(cycle: '120');
    expect(cubit.state.cycleMonths, ServiceType.maxCycleMonths);
    cubit.update(cycle: ' 024 ', price: '12,345');
    expect(cubit.state.cycleMonths, 24);
    expect(cubit.state.isPriceInvalid, isTrue);
    expect(cubit.state.canSave, isFalse);
    cubit.update(price: '250');
    expect(cubit.state.canSave, isTrue);
    await cubit.close();
  });

  test('a type of the user own cannot go without a name', () async {
    final cubit = build()
      ..init(tradeId: 't1', type: custom)
      ..update(name: '  ');

    expect(cubit.state.isNameMissing, isTrue);
    expect(cubit.state.canSave, isFalse);
    await cubit.close();
  });

  test('save passes the parsed values and signals', () async {
    when(
      () => catalogService.saveServiceType(
        id: 's2',
        tradeId: 't1',
        name: 'Wentylacja',
        cycleMonths: 24,
        defaultPriceGrosze: 25000,
        isArchived: true,
      ),
    ).thenAnswer((_) async {});
    final cubit = build()..init(tradeId: 't1', type: custom);
    final signals = <ServiceTypeFormSignal>[];
    final sub = cubit.signalStream.listen(signals.add);

    cubit.update(cycle: '24', price: '250', isArchived: true);
    await cubit.save();
    await Future<void>.delayed(Duration.zero);

    verify(
      () => catalogService.saveServiceType(
        id: 's2',
        tradeId: 't1',
        name: 'Wentylacja',
        cycleMonths: 24,
        defaultPriceGrosze: 25000,
        isArchived: true,
      ),
    ).called(1);
    expect(signals, [ServiceTypeFormSignal.saved]);
    expect(cubit.state.isSaving, isFalse);
    await sub.cancel();
    await cubit.close();
  });

  test('a new type saves without an id, and an empty price saves no price', () async {
    when(
      () => catalogService.saveServiceType(tradeId: 't1', name: 'Komin', cycleMonths: 12),
    ).thenAnswer((_) async {});
    final cubit = build()
      ..init(tradeId: 't1')
      ..update(name: 'Komin');
    await cubit.save();

    verify(
      () => catalogService.saveServiceType(tradeId: 't1', name: 'Komin', cycleMonths: 12),
    ).called(1);
    await cubit.close();
  });

  test('save does nothing while the form cannot be saved', () async {
    final cubit = build()..init(tradeId: 't1');

    await cubit.save();

    verifyNever(
      () => catalogService.saveServiceType(
        id: any(named: 'id'),
        tradeId: any(named: 'tradeId'),
        name: any(named: 'name'),
        cycleMonths: any(named: 'cycleMonths'),
        defaultPriceGrosze: any(named: 'defaultPriceGrosze'),
        isArchived: any(named: 'isArchived'),
      ),
    );
    await cubit.close();
  });

  test('a failed save goes to the error channel and allows a retry', () async {
    when(
      () => catalogService.saveServiceType(
        id: 's1',
        tradeId: 't1',
        name: '',
        cycleMonths: 12,
        defaultPriceGrosze: 18050,
      ),
    ).thenThrow(const ServiceTypeNotFoundException('s1'));
    final cubit = build()..init(tradeId: 't1', type: boiler);
    final errors = <Object>[];
    final sub = cubit.errorStream.listen(errors.add);

    await cubit.save();
    await Future<void>.delayed(Duration.zero);

    expect(errors.single, isA<LocalizedServiceTypeNotFoundException>());
    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.canSave, isTrue);
    await sub.cancel();
    await cubit.close();
  });
}
