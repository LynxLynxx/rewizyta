import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

class MockEquipmentService() extends Mock implements EquipmentService;

class MockCatalogService() extends Mock implements CatalogService;

class MockVisitsService() extends Mock implements VisitsService;

void main() {
  final now = DateTime.utc(2026);
  final today = DateTime.utc(2026, 11, 4);
  ServiceType type(String id, int cycleMonths) =>
      ServiceType(id: id, cycleMonths: cycleMonths, name: id, createdAt: now, updatedAt: now);
  Equipment item(String id, String serviceTypeId) => Equipment(
    id: id,
    clientId: 'c1',
    serviceTypeId: serviceTypeId,
    createdAt: now,
    updatedAt: now,
  );
  final chimney = item('e1', 'yearly');
  final boiler = item('e2', 'half');
  final visit = Visit(id: 'v1', clientId: 'c1', doneAt: today, createdAt: now, updatedAt: now);

  late MockEquipmentService equipmentService;
  late MockCatalogService catalogService;
  late MockVisitsService visitsService;

  VisitFormCubit build() =>
      VisitFormCubit(equipmentService, catalogService, visitsService, now: () => today);

  setUp(() {
    equipmentService = MockEquipmentService();
    catalogService = MockCatalogService();
    visitsService = MockVisitsService();
    when(() => equipmentService.findByClient('c1')).thenAnswer((_) async => [chimney, boiler]);
    when(
      catalogService.watchServiceTypes,
    ).thenAnswer((_) => Stream.value([type('yearly', 12), type('half', 6)]));
  });

  test('initial state is loading and cannot save', () {
    final cubit = build();
    expect(cubit.state, const VisitFormState());
    expect(cubit.state.canSave, isFalse);
    unawaited(cubit.close());
  });

  blocTest<VisitFormCubit, VisitFormState>(
    'init ticks every piece of equipment and dates the visit today',
    build: build,
    act: (cubit) => cubit.init('c1'),
    verify: (cubit) {
      final state = cubit.state;
      expect(state.isLoading, isFalse);
      expect(state.equipment.map((e) => e.id), ['e1', 'e2']);
      expect(state.ticked, {'e1', 'e2'});
      expect(state.date, '04.11.2026');
      expect(state.nextDueLabel, '04.05.2027');
      expect(state.canSave, isTrue);
    },
  );

  blocTest<VisitFormCubit, VisitFormState>(
    'the next due date follows what is ticked and the date',
    build: build,
    act: (cubit) async {
      await cubit.init('c1');
      cubit
        ..toggle('e2')
        ..update(date: '01.10.2026');
    },
    verify: (cubit) {
      expect(cubit.state.ticked, {'e1'});
      expect(cubit.state.nextDueLabel, '01.10.2027');
    },
  );

  blocTest<VisitFormCubit, VisitFormState>(
    'nothing ticked, a bad date or a bad price blocks the save',
    build: build,
    act: (cubit) async {
      await cubit.init('c1');
      cubit
        ..toggle('e1')
        ..toggle('e2');
      expect(cubit.state.canSave, isFalse);
      expect(cubit.state.nextDueLabel, isNull);
      cubit
        ..toggle('e1')
        ..update(date: '31.02.2026');
      expect(cubit.state.dateError, LastVisitError.invalid);
      cubit.update(date: '05.11.2026');
      expect(cubit.state.dateError, LastVisitError.future);
      cubit.update(date: '');
      expect(cubit.state.canSave, isFalse);
      cubit.update(date: '04.11.2026', price: '12,345');
      expect(cubit.state.isPriceInvalid, isTrue);
      expect(cubit.state.canSave, isFalse);
      cubit.update(price: '180,50');
    },
    verify: (cubit) {
      expect(cubit.state.isPriceInvalid, isFalse);
      expect(cubit.state.canSave, isTrue);
    },
  );

  test('save records the visit and signals', () async {
    when(
      () => visitsService.saveVisit(
        clientId: 'c1',
        doneAt: DateTime.utc(2026, 11, 3),
        equipmentIds: {'e1'},
        priceGrosze: 18050,
        note: 'Ciąg dobry',
      ),
    ).thenAnswer((_) async => visit);
    final cubit = build();
    final signals = <VisitFormSignal>[];
    final sub = cubit.signalStream.listen(signals.add);

    await cubit.init('c1');
    cubit
      ..toggle('e2')
      ..update(date: '03.11.2026', price: '180,50', note: 'Ciąg dobry');
    await cubit.save();
    await Future<void>.delayed(Duration.zero);

    expect(signals, [VisitFormSignal.saved]);
    expect(cubit.state.isSaving, isFalse);
    await sub.cancel();
    await cubit.close();
  });

  test('an empty price saves no price', () async {
    when(
      () => visitsService.saveVisit(
        clientId: 'c1',
        doneAt: today,
        equipmentIds: {'e1', 'e2'},
        note: '',
      ),
    ).thenAnswer((_) async => visit);
    final cubit = build();

    await cubit.init('c1');
    await cubit.save();

    verify(
      () => visitsService.saveVisit(
        clientId: 'c1',
        doneAt: today,
        equipmentIds: {'e1', 'e2'},
        note: '',
      ),
    ).called(1);
    await cubit.close();
  });

  test('save does nothing while the form cannot be saved', () async {
    final cubit = build();

    await cubit.save();

    verifyNever(
      () => visitsService.saveVisit(
        clientId: any(named: 'clientId'),
        doneAt: any(named: 'doneAt'),
        equipmentIds: any(named: 'equipmentIds'),
      ),
    );
    await cubit.close();
  });

  test('a failing save goes to the error channel and allows a retry', () async {
    when(
      () => visitsService.saveVisit(
        clientId: 'c1',
        doneAt: today,
        equipmentIds: {'e1', 'e2'},
        note: '',
      ),
    ).thenThrow(const ClientNotFoundException('c1'));
    final cubit = build();
    final errors = <Object>[];
    final sub = cubit.errorStream.listen(errors.add);

    await cubit.init('c1');
    await cubit.save();
    await Future<void>.delayed(Duration.zero);

    expect(errors.single, isA<LocalizedClientNotFoundException>());
    expect(cubit.state.canSave, isTrue);
    await sub.cancel();
    await cubit.close();
  });

  test('a failing load goes to the error channel', () async {
    when(
      () => equipmentService.findByClient('c1'),
    ).thenThrow(const ClientNotFoundException('c1'));
    final cubit = build();
    final errors = <Object>[];
    final sub = cubit.errorStream.listen(errors.add);

    await cubit.init('c1');
    await Future<void>.delayed(Duration.zero);

    expect(errors.single, isA<LocalizedClientNotFoundException>());
    await sub.cancel();
    await cubit.close();
  });

  group('editing a visit from the history', () {
    final stored = Visit(
      id: 'v1',
      clientId: 'c1',
      doneAt: DateTime.utc(2026, 10, 2),
      priceGrosze: 18050,
      note: 'Sadza',
      appointmentId: 'a1',
      createdAt: now,
      updatedAt: now,
    );
    VisitItem visitItem(String equipmentId) => VisitItem(
      id: 'i-$equipmentId',
      visitId: 'v1',
      equipmentId: equipmentId,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() {
      when(() => visitsService.getVisit('v1')).thenAnswer((_) async => stored);
      // e-gone was deleted since: no chip, but the item stays ticked.
      when(
        () => visitsService.findItems('v1'),
      ).thenAnswer((_) async => [visitItem('e2'), visitItem('e-gone')]);
    });

    blocTest<VisitFormCubit, VisitFormState>(
      'init fills the form from the stored visit',
      build: build,
      act: (cubit) => cubit.init('c1', visitId: 'v1'),
      verify: (cubit) {
        final state = cubit.state;
        expect(state.isEditing, isTrue);
        expect(state.ticked, {'e2', 'e-gone'});
        expect((state.date, state.price, state.note), ('02.10.2026', '180,50', 'Sadza'));
        expect(state.canSave, isTrue);
      },
    );

    test('save updates the same visit and keeps its appointment', () async {
      when(
        () => visitsService.saveVisit(
          id: 'v1',
          clientId: 'c1',
          doneAt: DateTime.utc(2026, 10, 2),
          equipmentIds: {'e1', 'e2', 'e-gone'},
          priceGrosze: 18050,
          note: 'Sadza',
          appointmentId: 'a1',
        ),
      ).thenAnswer((_) async => stored);
      final cubit = build();

      await cubit.init('c1', visitId: 'v1');
      cubit.toggle('e1');
      await cubit.save();

      verify(
        () => visitsService.saveVisit(
          id: 'v1',
          clientId: 'c1',
          doneAt: DateTime.utc(2026, 10, 2),
          equipmentIds: {'e1', 'e2', 'e-gone'},
          priceGrosze: 18050,
          note: 'Sadza',
          appointmentId: 'a1',
        ),
      ).called(1);
      await cubit.close();
    });

    test('delete soft-deletes the visit and signals', () async {
      when(() => visitsService.deleteVisit('v1')).thenAnswer((_) async {});
      final cubit = build();
      final signals = <VisitFormSignal>[];
      final sub = cubit.signalStream.listen(signals.add);

      await cubit.init('c1', visitId: 'v1');
      await cubit.delete();
      await Future<void>.delayed(Duration.zero);

      verify(() => visitsService.deleteVisit('v1')).called(1);
      expect(signals, [VisitFormSignal.deleted]);
      await sub.cancel();
      await cubit.close();
    });

    test('a failing delete goes to the error channel', () async {
      when(
        () => visitsService.deleteVisit('v1'),
      ).thenThrow(const VisitNotFoundException('v1'));
      final cubit = build();
      final errors = <Object>[];
      final sub = cubit.errorStream.listen(errors.add);

      await cubit.init('c1', visitId: 'v1');
      await cubit.delete();
      await Future<void>.delayed(Duration.zero);

      expect(errors, hasLength(1));
      expect(cubit.state.isSaving, isFalse);
      await sub.cancel();
      await cubit.close();
    });
  });

  test('delete does nothing for a new visit', () async {
    final cubit = build();

    await cubit.init('c1');
    await cubit.delete();

    verifyNever(() => visitsService.deleteVisit(any()));
    await cubit.close();
  });
}
