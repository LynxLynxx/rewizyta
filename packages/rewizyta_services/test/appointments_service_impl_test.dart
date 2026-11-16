import 'package:mocktail/mocktail.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'helpers/mocks.dart';

void main() {
  final earlier = DateTime.utc(2026, 11);
  // 12 November 2026, 10:00 local.
  final now = DateTime(2026, 11, 12, 10).toUtc();
  late MockAppointmentsRepository appointments;
  late FakeTransactionRunner transaction;
  late AppointmentsServiceImpl service;

  Appointment appointment({
    String id = 'a',
    DateTime? startsAt,
    AppointmentStatus status = AppointmentStatus.planned,
    bool isTimeFixed = false,
    int? routePosition,
    DateTime? deletedAt,
  }) => Appointment(
    id: id,
    clientId: 'c',
    startsAt: startsAt ?? DateTime(2026, 11, 13, 9).toUtc(),
    status: status,
    isTimeFixed: isTimeFixed,
    routePosition: routePosition,
    createdAt: earlier,
    updatedAt: earlier,
    deletedAt: deletedAt,
  );

  setUpAll(() => registerFallbackValue(appointment()));

  setUp(() {
    appointments = MockAppointmentsRepository();
    transaction = FakeTransactionRunner();
    when(() => appointments.upsert(any())).thenAnswer((_) async {});
    service = AppointmentsServiceImpl(
      appointments,
      transaction,
      settings: const PlannerSettings(slotMinutes: 90),
      now: () => now,
      uuid: const Uuid(),
    );
  });

  group('watchOpenBooking', () {
    test('emits the earliest planned appointment from today on', () async {
      when(() => appointments.watchByClient('c')).thenAnswer(
        (_) => Stream.value([
          appointment(id: 'far', startsAt: DateTime(2026, 12, 1, 9).toUtc()),
          appointment(id: 'done', status: AppointmentStatus.done),
          appointment(id: 'gone', deletedAt: earlier),
          appointment(id: 'yesterday', startsAt: DateTime(2026, 11, 11, 9).toUtc()),
          appointment(id: 'today', startsAt: DateTime(2026, 11, 12, 8).toUtc()),
          appointment(id: 'next'),
        ]),
      );

      expect((await service.watchOpenBooking('c').first)?.id, 'today');
    });

    test('emits null when nothing is open', () async {
      when(() => appointments.watchByClient('c')).thenAnswer((_) => Stream.value([]));

      expect(await service.watchOpenBooking('c').first, isNull);
    });
  });

  group('book', () {
    final slot = DateTime(2026, 11, 14, 11).toUtc();

    test('creates a planned appointment of the slot length', () async {
      when(() => appointments.findByClient('c')).thenAnswer((_) async => []);

      final booking = await service.book(clientId: 'c', startsAt: slot, isTimeFixed: true);

      expect(transaction.runs, 1);
      expect(booking.id, isNotEmpty);
      expect(booking.clientId, 'c');
      expect(booking.startsAt, slot);
      expect(booking.durationMinutes, 90);
      expect(booking.status, AppointmentStatus.planned);
      expect(booking.isTimeFixed, isTrue);
      expect((booking.createdAt, booking.updatedAt), (now, now));
      verify(() => appointments.upsert(booking)).called(1);
    });

    test('moves the open booking instead of adding a second one', () async {
      final open = appointment(isTimeFixed: true, routePosition: 3);
      when(() => appointments.findByClient('c')).thenAnswer(
        (_) async => [open, appointment(id: 'done', status: AppointmentStatus.done)],
      );

      final booking = await service.book(clientId: 'c', startsAt: slot);

      expect(booking.id, 'a');
      expect(booking.startsAt, slot);
      expect(booking.isTimeFixed, isFalse);
      expect(booking.routePosition, isNull);
      expect(booking.updatedAt, now);
      verify(() => appointments.upsert(booking)).called(1);
    });

    test('rejects an hour that has passed', () {
      expect(
        () => service.book(clientId: 'c', startsAt: now),
        throwsA(
          isA<AppointmentValidationException>().having(
            (e) => e.error,
            'error',
            AppointmentValidationError.inPast,
          ),
        ),
      );
      verifyNever(() => appointments.findByClient(any()));
    });
  });

  group('setStatus', () {
    test('saves the new status', () async {
      when(() => appointments.find('a')).thenAnswer((_) async => appointment());

      await service.setStatus('a', AppointmentStatus.cancelled);

      expect(transaction.runs, 1);
      verify(
        () => appointments.upsert(
          appointment().copyWith(status: AppointmentStatus.cancelled, updatedAt: now),
        ),
      ).called(1);
    });

    test('writes nothing when the status is the same', () async {
      when(() => appointments.find('a')).thenAnswer((_) async => appointment());

      await service.setStatus('a', AppointmentStatus.planned);

      verifyNever(() => appointments.upsert(any()));
    });

    test('throws for an unknown or deleted appointment', () async {
      when(() => appointments.find('x')).thenAnswer((_) async => null);
      when(() => appointments.find('gone')).thenAnswer(
        (_) async => appointment(id: 'gone', deletedAt: earlier),
      );

      await expectLater(
        service.setStatus('x', AppointmentStatus.noShow),
        throwsA(isA<AppointmentNotFoundException>()),
      );
      await expectLater(
        service.setStatus('gone', AppointmentStatus.noShow),
        throwsA(isA<AppointmentNotFoundException>()),
      );
    });
  });
}
