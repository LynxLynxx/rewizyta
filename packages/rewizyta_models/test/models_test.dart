import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2026, 9, 28, 10);
  final t1 = DateTime.utc(2026, 9, 29, 10);

  group('copyWith', () {
    test('keeps every field when nothing is passed', () {
      final client = Client(
        id: 'c1',
        name: 'Jan',
        phone: '+48601234567',
        lat: 49.48,
        note: 'Pies',
        createdAt: t0,
        updatedAt: t0,
        deletedAt: t1,
      );
      final appointment = Appointment(
        id: 'a1',
        clientId: 'c1',
        startsAt: t1,
        routePosition: 2,
        note: 'Brama',
        createdAt: t0,
        updatedAt: t0,
      );

      expect(client.copyWith(), client);
      expect(appointment.copyWith(), appointment);
    });

    test('sets and clears nullable fields through Optional', () {
      final client = Client(
        id: 'c1',
        name: 'Jan',
        phone: '+48601234567',
        createdAt: t0,
        updatedAt: t0,
      );

      final cleared = client.copyWith(phone: const Optional.empty(), note: const Optional('Pies'));

      expect(cleared.phone, isNull);
      expect(cleared.note, 'Pies');
      expect(cleared.name, 'Jan');
    });

    test('soft-deletes and restores a row', () {
      final trade = Trade(id: 't1', template: TradeTemplate.chimney, createdAt: t0, updatedAt: t0);

      final deleted = trade.copyWith(deletedAt: Optional(t1), updatedAt: t1);
      expect(deleted.isDeleted, isTrue);
      expect(deleted.template, TradeTemplate.chimney);

      final restored = deleted.copyWith(deletedAt: const Optional.empty());
      expect(restored.isDeleted, isFalse);
      expect(restored.updatedAt, t1);
    });

    test('a renamed default can go back to its localized name', () {
      final trade = Trade(id: 't1', template: TradeTemplate.gas, createdAt: t0, updatedAt: t0);

      final renamed = trade.copyWith(name: const Optional('Gaz'));
      expect(renamed.name, 'Gaz');
      expect(renamed.copyWith(name: const Optional.empty()).name, isNull);
    });

    test("a row of the user's own cannot lose its name", () {
      final trade = Trade(id: 't1', name: 'Hydraulik', createdAt: t0, updatedAt: t0);
      final type = ServiceType(
        id: 's1',
        name: 'Przegląd',
        cycleMonths: 12,
        createdAt: t0,
        updatedAt: t0,
      );

      expect(() => trade.copyWith(name: const Optional.empty()), throwsA(isA<AssertionError>()));
      expect(() => type.copyWith(name: const Optional.empty()), throwsA(isA<AssertionError>()));
    });

    test('clears the optional links of every model that has them', () {
      final type = ServiceType(
        id: 's1',
        name: 'Przegląd',
        cycleMonths: 12,
        tradeId: 't1',
        defaultPriceGrosze: 25000,
        createdAt: t0,
        updatedAt: t0,
      );
      final visit = Visit(
        id: 'v1',
        clientId: 'c1',
        doneAt: DateTime.utc(2026, 9),
        priceGrosze: 18000,
        appointmentId: 'a1',
        createdAt: t0,
        updatedAt: t0,
      );
      final appointment = Appointment(
        id: 'a1',
        clientId: 'c1',
        startsAt: t1,
        routePosition: 2,
        createdAt: t0,
        updatedAt: t0,
      );
      final device = Device(
        id: 'd1',
        platform: DevicePlatform.android,
        pushToken: 'token',
        pushProvider: PushProvider.fcm,
        createdAt: t0,
        updatedAt: t0,
      );

      final loose = type.copyWith(
        tradeId: const Optional.empty(),
        defaultPriceGrosze: const Optional.empty(),
      );
      expect([loose.tradeId, loose.defaultPriceGrosze], [null, null]);
      expect(visit.copyWith(appointmentId: const Optional.empty()).appointmentId, isNull);
      expect(visit.copyWith(priceGrosze: const Optional.empty()).priceGrosze, isNull);
      expect(appointment.copyWith(routePosition: const Optional.empty()).routePosition, isNull);
      final unregistered = device.copyWith(
        pushToken: const Optional.empty(),
        pushProvider: const Optional.empty(),
      );
      expect([unregistered.pushToken, unregistered.pushProvider], [null, null]);
    });

    test('restores an unticked visit item', () {
      final item = VisitItem(
        id: 'i1',
        visitId: 'v1',
        equipmentId: 'e1',
        createdAt: t0,
        updatedAt: t0,
        deletedAt: t0,
      );

      final restored = item.copyWith(deletedAt: const Optional.empty(), updatedAt: t1);

      expect(restored.isDeleted, isFalse);
      expect(restored.updatedAt, t1);
    });
  });

  group('Equipment', () {
    final equipment = Equipment(
      id: 'e1',
      clientId: 'c1',
      serviceTypeId: 's1',
      createdAt: t0,
      updatedAt: t0,
    );

    test('copyWith never touches the due-date cache', () {
      final due = equipment.withDue(
        lastVisitAt: DateTime.utc(2026, 1, 31),
        nextDueAt: DateTime.utc(2027, 1, 31),
        updatedAt: t1,
      );

      final relabelled = due.copyWith(label: const Optional('Komin – kuchnia'));

      expect(relabelled.lastVisitAt, DateTime.utc(2026, 1, 31));
      expect(relabelled.nextDueAt, DateTime.utc(2027, 1, 31));
    });

    test('withDue sets and clears both caches and stamps updatedAt', () {
      final due = equipment.withDue(
        lastVisitAt: DateTime.utc(2026, 1, 31),
        nextDueAt: DateTime.utc(2027, 1, 31),
        updatedAt: t1,
      );
      final cleared = due.withDue(lastVisitAt: null, nextDueAt: null, updatedAt: t1);

      expect(due.updatedAt, t1);
      expect(due.label, equipment.label);
      expect([cleared.lastVisitAt, cleared.nextDueAt], [null, null]);
    });
  });
}
