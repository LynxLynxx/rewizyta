import 'package:mocktail/mocktail.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:test/test.dart';

import 'helpers/mocks.dart';

void main() {
  final earlier = DateTime.utc(2026, 3, 31);
  final now = DateTime.utc(2026, 10, 22, 12);
  late MockEquipmentRepository equipment;
  late MockServiceTypesRepository serviceTypes;
  late MockVisitsRepository visits;
  late FakeTransactionRunner transaction;
  late EquipmentServiceImpl service;

  ServiceType type(String id, int cycleMonths) => ServiceType(
    id: id,
    name: id,
    cycleMonths: cycleMonths,
    createdAt: earlier,
    updatedAt: earlier,
  );
  final stored = Equipment(
    id: 'e',
    clientId: 'c',
    serviceTypeId: 'yearly',
    label: 'Kuchnia',
    lastVisitAt: earlier,
    nextDueAt: DateTime.utc(2027, 3, 31),
    createdAt: earlier,
    updatedAt: earlier,
  );

  setUpAll(() => registerFallbackValue(stored));

  setUp(() {
    equipment = MockEquipmentRepository();
    serviceTypes = MockServiceTypesRepository();
    visits = MockVisitsRepository();
    transaction = FakeTransactionRunner();
    when(() => serviceTypes.find('yearly')).thenAnswer((_) async => type('yearly', 12));
    when(() => serviceTypes.find('quarterly')).thenAnswer((_) async => type('quarterly', 3));
    when(() => serviceTypes.find('missing')).thenAnswer((_) async => null);
    when(() => equipment.find('e')).thenAnswer((_) async => stored);
    when(() => equipment.upsert(any())).thenAnswer((_) async {});
    service = EquipmentServiceImpl(equipment, serviceTypes, visits, transaction, now: () => now);
  });

  group('saveEquipment', () {
    test('adds equipment with no due dates until its first visit', () async {
      when(() => visits.lastDoneAt(any())).thenAnswer((_) async => null);

      final added = await service.saveEquipment(
        clientId: 'c',
        serviceTypeId: 'yearly',
        label: ' Łazienka ',
        count: 2,
        note: '',
      );

      expect(transaction.runs, 1);
      expect(added.id, isNotEmpty);
      expect((added.label, added.count, added.note), ('Łazienka', 2, null));
      expect((added.lastVisitAt, added.nextDueAt), (null, null));
      expect((added.createdAt, added.updatedAt), (now, now));
      verify(() => equipment.upsert(added)).called(1);
    });

    test('moves the due date when the service type changes', () async {
      when(() => visits.lastDoneAt('e')).thenAnswer((_) async => earlier);

      final saved = await service.saveEquipment(
        id: 'e',
        clientId: 'c',
        serviceTypeId: 'quarterly',
        label: 'Kuchnia',
      );

      expect(saved.serviceTypeId, 'quarterly');
      expect((saved.lastVisitAt, saved.nextDueAt), (earlier, DateTime.utc(2026, 6, 30)));
      expect((saved.createdAt, saved.updatedAt), (earlier, now));
      verify(() => equipment.upsert(saved)).called(1);
    });

    test('rejects a count below one', () {
      expect(
        () => service.saveEquipment(clientId: 'c', serviceTypeId: 'yearly', count: 0),
        throwsA(
          isA<EquipmentValidationException>().having(
            (e) => e.error,
            'error',
            EquipmentValidationError.countBelowOne,
          ),
        ),
      );
      expect(transaction.runs, 0);
    });

    test('throws for an unknown service type or equipment id', () async {
      await expectLater(
        service.saveEquipment(clientId: 'c', serviceTypeId: 'missing'),
        throwsA(isA<ServiceTypeNotFoundException>()),
      );
      when(() => equipment.find('x')).thenAnswer((_) async => null);
      await expectLater(
        service.saveEquipment(id: 'x', clientId: 'c', serviceTypeId: 'yearly'),
        throwsA(isA<EquipmentNotFoundException>()),
      );
      verifyNever(() => equipment.upsert(any()));
    });
  });
}
