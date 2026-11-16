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
  late MockAppointmentsRepository appointments;
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

  /// A planned appointment of client `c` at 09:00 on 22 October.
  Appointment booking({
    String id = 'a',
    AppointmentStatus status = AppointmentStatus.planned,
    DateTime? startsAt,
    DateTime? deletedAt,
  }) => Appointment(
    id: id,
    clientId: 'c',
    startsAt: startsAt ?? DateTime(2026, 10, 22, 9).toUtc(),
    status: status,
    createdAt: earlier,
    updatedAt: earlier,
    deletedAt: deletedAt,
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
    registerFallbackValue(booking());
  });

  setUp(() {
    visits = MockVisitsRepository();
    visitItems = MockVisitItemsRepository();
    equipment = MockEquipmentRepository();
    serviceTypes = MockServiceTypesRepository();
    appointments = MockAppointmentsRepository();
    transaction = FakeTransactionRunner();
    when(() => visits.upsert(any())).thenAnswer((_) async {});
    when(() => visitItems.upsert(any())).thenAnswer((_) async {});
    when(() => equipment.upsert(any())).thenAnswer((_) async {});
    when(() => serviceTypes.find('st')).thenAnswer((_) async => serviceType);
    when(() => appointments.upsert(any())).thenAnswer((_) async {});
    when(() => appointments.findByClient(any())).thenAnswer((_) async => []);
    service = VisitsServiceImpl(
      visits,
      visitItems,
      equipment,
      serviceTypes,
      appointments,
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

  group('restoreVisit', () {
    test('restores the visit and moves the due dates forward again', () async {
      final deleted = storedVisit.copyWith(deletedAt: Optional(earlier));
      when(() => visits.find('v')).thenAnswer((_) async => deleted);
      when(() => visitItems.findByVisit('v')).thenAnswer((_) async => [visitItem('e1')]);
      stubEquipment(item('e1'), earlier);

      await service.restoreVisit('v');

      expect(transaction.runs, 1);
      verify(
        () => visits.upsert(deleted.copyWith(updatedAt: now, deletedAt: const Optional.empty())),
      ).called(1);
      expect(upsertedEquipment().single.lastVisitAt, earlier);
    });

    test('throws for an unknown visit id', () async {
      when(() => visits.find('x')).thenAnswer((_) async => null);

      await expectLater(service.restoreVisit('x'), throwsA(isA<VisitNotFoundException>()));
    });
  });

  group('appointments', () {
    void stubEquipmentFor(String id) => stubEquipment(item(id), today);

    test("a new visit fulfils the client's planned appointment of that day", () async {
      stubEquipmentFor('e1');
      when(() => appointments.findByClient('c')).thenAnswer(
        (_) async => [
          booking(id: 'later', startsAt: DateTime(2026, 10, 22, 14).toUtc()),
          booking(id: 'other-day', startsAt: DateTime(2026, 10, 23, 9).toUtc()),
          booking(id: 'cancelled', status: AppointmentStatus.cancelled),
          booking(),
        ],
      );

      final visit = await service.saveVisit(
        clientId: 'c',
        doneAt: DateTime(2026, 10, 22),
        equipmentIds: {'e1'},
      );

      expect(visit.appointmentId, 'a');
      verify(
        () => appointments.upsert(
          booking().copyWith(status: AppointmentStatus.done, updatedAt: now),
        ),
      ).called(1);
    });

    test('a visit on a day without a booking links nothing', () async {
      stubEquipmentFor('e1');
      when(() => appointments.findByClient('c')).thenAnswer(
        (_) async => [booking(startsAt: DateTime(2026, 10, 25, 9).toUtc())],
      );

      final visit = await service.saveVisit(
        clientId: 'c',
        doneAt: DateTime(2026, 10, 22),
        equipmentIds: {'e1'},
      );

      expect(visit.appointmentId, isNull);
      verifyNever(() => appointments.upsert(any()));
    });

    test('a named appointment is marked done, a cancelled one is left alone', () async {
      stubEquipmentFor('e1');
      when(() => appointments.find('a')).thenAnswer((_) async => booking());
      when(() => appointments.find('x')).thenAnswer(
        (_) async => booking(id: 'x', status: AppointmentStatus.cancelled),
      );

      await service.saveVisit(
        clientId: 'c',
        doneAt: today,
        equipmentIds: {'e1'},
        appointmentId: 'a',
      );
      await service.saveVisit(
        clientId: 'c',
        doneAt: today,
        equipmentIds: {'e1'},
        appointmentId: 'x',
      );

      final saved = verify(() => appointments.upsert(captureAny())).captured.cast<Appointment>();
      expect(saved.map((a) => (a.id, a.status)), [('a', AppointmentStatus.done)]);
    });

    test('editing a visit does not look for a booking', () async {
      when(() => visits.find('v')).thenAnswer((_) async => storedVisit);
      when(() => visitItems.findByVisit('v')).thenAnswer((_) async => []);
      stubEquipmentFor('e1');

      await service.saveVisit(id: 'v', clientId: 'c', doneAt: today, equipmentIds: {'e1'});

      verifyNever(() => appointments.findByClient(any()));
    });

    test(
      'deleting the visit puts its done appointment back to planned, restoring redoes it',
      () async {
        final fulfilled = storedVisit.copyWith(appointmentId: const Optional('a'));
        when(() => visits.find('v')).thenAnswer((_) async => fulfilled);
        when(() => visitItems.findByVisit('v')).thenAnswer((_) async => []);
        when(() => appointments.find('a'))
            .thenAnswer((_) async => booking(status: AppointmentStatus.done));

        await service.deleteVisit('v');

        verify(() => appointments.upsert(booking().copyWith(updatedAt: now))).called(1);

        when(() => appointments.find('a')).thenAnswer((_) async => booking());
        await service.restoreVisit('v');

        verify(
          () => appointments.upsert(
            booking().copyWith(status: AppointmentStatus.done, updatedAt: now),
          ),
        ).called(1);
      },
    );

    test('deleting a visit leaves a cancelled or deleted appointment alone', () async {
      final fulfilled = storedVisit.copyWith(appointmentId: const Optional('a'));
      when(() => visits.find('v')).thenAnswer((_) async => fulfilled);
      when(() => visitItems.findByVisit('v')).thenAnswer((_) async => []);
      when(() => appointments.find('a')).thenAnswer(
        (_) async => booking(status: AppointmentStatus.noShow),
      );

      await service.deleteVisit('v');

      when(() => appointments.find('a')).thenAnswer(
        (_) async => booking(status: AppointmentStatus.done, deletedAt: earlier),
      );
      await service.deleteVisit('v');

      verifyNever(() => appointments.upsert(any()));
    });
  });

  group('reads', () {
    test('watchByClient and watchItemsByClient pass through', () async {
      when(() => visits.watchByClient('c')).thenAnswer((_) => Stream.value([storedVisit]));
      when(
        () => visitItems.watchByClient('c'),
      ).thenAnswer((_) => Stream.value([visitItem('e1')]));

      expect(await service.watchByClient('c').first, [storedVisit]);
      expect(await service.watchItemsByClient('c').first, [visitItem('e1')]);
    });

    test('getVisit returns the visit and throws for an unknown id', () async {
      when(() => visits.find('v')).thenAnswer((_) async => storedVisit);
      when(() => visits.find('x')).thenAnswer((_) async => null);

      expect(await service.getVisit('v'), storedVisit);
      await expectLater(service.getVisit('x'), throwsA(isA<VisitNotFoundException>()));
    });

    test('findItems leaves out unticked items', () async {
      when(() => visitItems.findByVisit('v')).thenAnswer(
        (_) async => [visitItem('e1'), visitItem('e2', deletedAt: earlier)],
      );

      expect(await service.findItems('v'), [visitItem('e1')]);
    });
  });
}
