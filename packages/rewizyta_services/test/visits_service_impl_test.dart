import 'package:mocktail/mocktail.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:test/test.dart';

import 'helpers/mocks.dart';

void main() {
  final earlier = DateTime.utc(2026, 3, 2);
  final now = DateTime.utc(2026, 10, 22, 12);
  final today = DateTime.utc(2026, 10, 22);
  late MockVisitsRepository visits;
  late MockVisitItemsRepository visitItems;
  late MockEquipmentRepository equipment;
  late MockServiceTypesRepository serviceTypes;
  late FakeTransactionRunner transaction;
  late VisitsServiceImpl service;

  final serviceType = ServiceType(
    id: 'st',
    name: 'Przegląd',
    cycleMonths: 12,
    createdAt: earlier,
    updatedAt: earlier,
  );
  Equipment item(String id, {DateTime? lastVisitAt, DateTime? deletedAt}) => Equipment(
    id: id,
    clientId: 'c',
    serviceTypeId: 'st',
    lastVisitAt: lastVisitAt,
    nextDueAt: lastVisitAt == null ? null : nextDue(lastVisitAt, 12),
    createdAt: earlier,
    updatedAt: earlier,
    deletedAt: deletedAt,
  );
  VisitItem visitItem(String equipmentId, {DateTime? deletedAt}) => VisitItem(
    id: 'item-$equipmentId',
    visitId: 'v',
    equipmentId: equipmentId,
    createdAt: earlier,
    updatedAt: earlier,
    deletedAt: deletedAt,
  );
  final storedVisit = Visit(
    id: 'v',
    clientId: 'c',
    doneAt: earlier,
    priceGrosze: 20000,
    createdAt: earlier,
    updatedAt: earlier,
  );

  List<VisitItem> upsertedItems() =>
      verify(() => visitItems.upsert(captureAny())).captured.cast<VisitItem>();
  List<Equipment> upsertedEquipment() =>
      verify(() => equipment.upsert(captureAny())).captured.cast<Equipment>();

  /// Stubs equipment [id] as stored and its latest visit as [lastDoneAt].
  void stubEquipment(Equipment stored, DateTime? lastDoneAt) {
    when(() => equipment.find(stored.id)).thenAnswer((_) async => stored);
    when(() => visits.lastDoneAt(stored.id)).thenAnswer((_) async => lastDoneAt);
  }

  setUpAll(() {
    registerFallbackValue(storedVisit);
    registerFallbackValue(visitItem(''));
    registerFallbackValue(item(''));
  });

  setUp(() {
    visits = MockVisitsRepository();
    visitItems = MockVisitItemsRepository();
    equipment = MockEquipmentRepository();
    serviceTypes = MockServiceTypesRepository();
    transaction = FakeTransactionRunner();
    when(() => visits.upsert(any())).thenAnswer((_) async {});
    when(() => visitItems.upsert(any())).thenAnswer((_) async {});
    when(() => equipment.upsert(any())).thenAnswer((_) async {});
    when(() => serviceTypes.find('st')).thenAnswer((_) async => serviceType);
    service = VisitsServiceImpl(
      visits,
      visitItems,
      equipment,
      serviceTypes,
      transaction,
      now: () => now,
    );
  });

  group('saveVisit', () {
    test('records the visit, its items and the new due dates in one transaction', () async {
      stubEquipment(item('e1'), today);
      stubEquipment(item('e2', lastVisitAt: earlier), today);

      final visit = await service.saveVisit(
        clientId: 'c',
        doneAt: DateTime(2026, 10, 22, 15, 30),
        equipmentIds: {'e1', 'e2'},
        priceGrosze: 25000,
        note: ' ',
      );

      expect(transaction.runs, 1);
      expect(visit.id, isNotEmpty);
      expect(visit.doneAt, today);
      expect(visit.priceGrosze, 25000);
      expect(visit.note, isNull);
      expect((visit.createdAt, visit.updatedAt), (now, now));
      verify(() => visits.upsert(visit)).called(1);
      verifyNever(() => visitItems.findByVisit(any()));
      final items = upsertedItems();
      expect(items.map((i) => (i.visitId, i.equipmentId)), [(visit.id, 'e1'), (visit.id, 'e2')]);
      final saved = upsertedEquipment();
      expect(saved.map((e) => (e.id, e.lastVisitAt, e.nextDueAt, e.updatedAt)), [
        ('e1', today, DateTime.utc(2027, 10, 22), now),
        ('e2', today, DateTime.utc(2027, 10, 22), now),
      ]);
    });

    test('unticks, restores and adds items, and recomputes every equipment involved', () async {
      when(() => visits.find('v')).thenAnswer((_) async => storedVisit);
      when(() => visitItems.findByVisit('v')).thenAnswer(
        (_) async => [
          visitItem('kept'),
          visitItem('dropped'),
          visitItem('restored', deletedAt: earlier),
        ],
      );
      stubEquipment(item('kept', lastVisitAt: earlier), earlier);
      stubEquipment(item('dropped', lastVisitAt: earlier), null);
      stubEquipment(item('restored'), earlier);
      stubEquipment(item('added'), earlier);

      final visit = await service.saveVisit(
        id: 'v',
        clientId: 'c',
        doneAt: earlier,
        equipmentIds: {'kept', 'restored', 'added'},
      );

      expect(visit.id, 'v');
      expect(visit.createdAt, earlier);
      expect(visit.priceGrosze, isNull);
      final items = upsertedItems();
      expect(items.map((i) => (i.equipmentId, i.deletedAt)), [
        ('dropped', now),
        ('restored', null),
        ('added', null),
      ]);
      expect(items.take(2).map((i) => i.id), ['item-dropped', 'item-restored']);
      expect((items.last.visitId, items.last.createdAt), ('v', now));
      // 'kept' was current and is not written again.
      expect(upsertedEquipment().map((e) => (e.id, e.lastVisitAt)), [
        ('dropped', null),
        ('restored', earlier),
        ('added', earlier),
      ]);
    });

    test('leaves soft-deleted equipment alone', () async {
      stubEquipment(item('gone', deletedAt: earlier), today);

      await service.saveVisit(clientId: 'c', doneAt: today, equipmentIds: {'gone'});

      verifyNever(() => equipment.upsert(any()));
    });

    test('rejects a negative price', () {
      expect(
        () => service.saveVisit(clientId: 'c', doneAt: today, equipmentIds: {}, priceGrosze: -1),
        throwsA(
          isA<VisitValidationException>().having(
            (e) => e.error,
            'error',
            VisitValidationError.priceNegative,
          ),
        ),
      );
      expect(transaction.runs, 0);
    });

    test('throws for an unknown visit id', () async {
      when(() => visits.find('x')).thenAnswer((_) async => null);

      await expectLater(
        service.saveVisit(id: 'x', clientId: 'c', doneAt: today, equipmentIds: {}),
        throwsA(isA<VisitNotFoundException>()),
      );
      verifyNever(() => visits.upsert(any()));
    });
  });

  group('deleteVisit', () {
    test('soft-deletes the visit and moves the due dates back', () async {
      when(() => visits.find('v')).thenAnswer((_) async => storedVisit);
      when(() => visitItems.findByVisit('v')).thenAnswer((_) async => [visitItem('e1')]);
      stubEquipment(item('e1', lastVisitAt: earlier), null);

      await service.deleteVisit('v');

      expect(transaction.runs, 1);
      verify(
        () => visits.upsert(storedVisit.copyWith(updatedAt: now, deletedAt: Optional(now))),
      ).called(1);
      final saved = upsertedEquipment().single;
      expect((saved.lastVisitAt, saved.nextDueAt, saved.updatedAt), (null, null, now));
      verifyNever(() => visitItems.upsert(any()));
    });

    test('throws for an unknown visit id', () async {
      when(() => visits.find('x')).thenAnswer((_) async => null);

      await expectLater(service.deleteVisit('x'), throwsA(isA<VisitNotFoundException>()));
    });
  });
}
