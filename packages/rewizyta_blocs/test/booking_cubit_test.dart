import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

class MockAppointmentsService() extends Mock implements AppointmentsService;

class MockDayPlanService() extends Mock implements DayPlanService;

void main() {
  final created = DateTime.utc(2026, 11);
  // Thursday 12 November 2026, 10:00 local.
  final now = DateTime(2026, 11, 12, 10);
  final firstDay = DateTime(2026, 11, 12);

  late MockAppointmentsService appointments;
  late MockDayPlanService dayPlans;
  late StreamController<Appointment?> open;
  late StreamController<List<DayPlan>> plans;
  late BookingCubit cubit;

  DateTime at(int day, int hour) => DateTime(2026, 11, day, hour).toUtc();

  Appointment appointment(String id, DateTime startsAt, {bool isTimeFixed = false}) => Appointment(
    id: id,
    clientId: 'c1',
    startsAt: startsAt,
    isTimeFixed: isTimeFixed,
    createdAt: created,
    updatedAt: created,
  );

  DayStop stop(Appointment appointment) => DayStop(
    appointment: appointment,
    client: Client(id: appointment.clientId, name: 'X', createdAt: created, updatedAt: created),
  );

  /// Seven plans from 12 November; [stops] by day offset.
  List<DayPlan> week({
    PlannerSettings settings = const PlannerSettings(),
    Map<int, List<Appointment>> stops = const {},
  }) => [
    for (var i = 0; i < 7; i++)
      DayPlan.of([for (final a in stops[i] ?? const <Appointment>[]) stop(a)], settings),
  ];

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// Inits the cubit and delivers the open booking and the week.
  Future<void> load({Appointment? booking, List<DayPlan>? days}) async {
    cubit.init('c1');
    open.add(booking);
    plans.add(days ?? week());
    await settle();
  }

  setUpAll(() => registerFallbackValue(AppointmentStatus.planned));

  setUp(() {
    appointments = MockAppointmentsService();
    dayPlans = MockDayPlanService();
    open = StreamController<Appointment?>.broadcast();
    plans = StreamController<List<DayPlan>>.broadcast();
    when(() => appointments.watchOpenBooking('c1')).thenAnswer((_) => open.stream);
    when(() => dayPlans.watchDays(firstDay, 7)).thenAnswer((_) => plans.stream);
    cubit = BookingCubit(appointments, dayPlans, now: () => now);
  });

  tearDown(() async {
    await cubit.close();
    await open.close();
    await plans.close();
  });

  test('stays loading until the booking and the week have arrived', () async {
    cubit.init('c1');
    plans.add(week());
    await settle();

    expect(cubit.state.isLoading, isTrue);

    open.add(null);
    await settle();

    expect(cubit.state.isLoading, isFalse);
  });

  test("offers today's remaining hours first, with a week of days", () async {
    await load();

    final state = cubit.state;
    expect(state.days.map((d) => d.date), [for (var i = 0; i < 7; i++) DateTime(2026, 11, 12 + i)]);
    expect(state.selectedDay, 0);
    expect(state.slots, [for (var h = 11; h < 16; h++) at(12, h)]);
    expect(state.selectedSlot, isNull);
    expect(state.hasBooking, isFalse);
    expect(state.canGoBack, isFalse);
    expect(state.canBook, isFalse);
  });

  test('a full day shows its visits and the first day with room is chosen', () async {
    const small = PlannerSettings(slotsPerDay: 1);
    await load(
      days: week(
        settings: small,
        stops: {
          0: [appointment('a', at(12, 11))],
        },
      ),
    );

    expect(cubit.state.days.first.visitCount, 1);
    expect(cubit.state.selectedDay, 1);
    expect(cubit.state.slots, hasLength(8));
  });

  test('the client own booking does not take a slot while it is moved', () async {
    final own = appointment('own', at(13, 9));
    await load(
      booking: own,
      days: week(
        stops: {
          1: [own, appointment('other', at(13, 10))],
        },
      ),
    );

    cubit.selectDay(1);

    expect(cubit.state.hasBooking, isTrue);
    expect(cubit.state.days[1].visitCount, 1);
    expect(cubit.state.slots, contains(at(13, 9)));
    expect(cubit.state.slots, isNot(contains(at(13, 10))));
  });

  test('the switch starts from the open booking', () async {
    await load(booking: appointment('own', at(13, 9), isTimeFixed: true));

    expect(cubit.state.isTimeFixed, isTrue);

    cubit.setTimeFixed(value: false);

    expect(cubit.state.isTimeFixed, isFalse);
  });

  test('picking a day clears the hour, picking the same hour again unpicks it', () async {
    await load();

    cubit.selectSlot(at(12, 12));
    expect(cubit.state.selectedSlot, at(12, 12));
    expect(cubit.state.canBook, isTrue);

    cubit.selectSlot(at(12, 12));
    expect(cubit.state.selectedSlot, isNull);

    cubit
      ..selectSlot(at(12, 12))
      ..selectDay(2);
    expect(cubit.state.selectedDay, 2);
    expect(cubit.state.selectedSlot, isNull);
    expect(cubit.state.slots.first, at(14, 8));
  });

  test('an hour taken meanwhile drops out of the pick', () async {
    await load();
    cubit.selectSlot(at(12, 12));

    plans.add(
      week(
        stops: {
          0: [appointment('new', at(12, 12))],
        },
      ),
    );
    await settle();

    expect(cubit.state.selectedSlot, isNull);
    expect(cubit.state.slots, isNot(contains(at(12, 12))));
  });

  test('selectDay ignores an index outside the week', () async {
    await load();

    cubit.selectDay(9);

    expect(cubit.state.selectedDay, 0);
  });

  test('the week arrows move by seven days and stop at today', () async {
    final nextStart = DateTime(2026, 11, 19);
    final next = StreamController<List<DayPlan>>.broadcast();
    addTearDown(next.close);
    when(() => dayPlans.watchDays(nextStart, 7)).thenAnswer((_) => next.stream);
    await load();

    cubit.previousWeek();
    verifyNever(() => dayPlans.watchDays(DateTime(2026, 11, 5), 7));

    cubit.nextWeek();
    expect(cubit.state.isLoading, isTrue);
    next.add([
      for (var i = 0; i < 7; i++) DayPlan.of(const [], const PlannerSettings()),
    ]);
    await settle();

    expect(cubit.state.days.first.date, nextStart);
    expect(cubit.state.canGoBack, isTrue);
    // A later week has its whole grid.
    expect(cubit.state.slots, hasLength(8));

    cubit.previousWeek();
    plans.add(week());
    await settle();
    expect(cubit.state.days.first.date, firstDay);
    expect(cubit.state.canGoBack, isFalse);
  });

  group('book', () {
    test('books the picked hour with the switch and signals the page', () async {
      when(
        () => appointments.book(
          clientId: any(named: 'clientId'),
          startsAt: any(named: 'startsAt'),
          isTimeFixed: any(named: 'isTimeFixed'),
        ),
      ).thenAnswer((_) async => appointment('a', at(12, 12)));
      await load();
      final signals = <BookingSignal>[];
      final sub = cubit.signalStream.listen(signals.add);
      cubit
        ..selectSlot(at(12, 12))
        ..setTimeFixed(value: true);

      await cubit.book();
      await settle();

      verify(
        () => appointments.book(clientId: 'c1', startsAt: at(12, 12), isTimeFixed: true),
      ).called(1);
      expect(signals, [BookingSignal.booked]);
      await sub.cancel();
    });

    test('a second tap while the first write runs writes and signals once', () async {
      final write = Completer<Appointment>();
      when(
        () => appointments.book(
          clientId: any(named: 'clientId'),
          startsAt: any(named: 'startsAt'),
          isTimeFixed: any(named: 'isTimeFixed'),
        ),
      ).thenAnswer((_) => write.future);
      await load();
      final signals = <BookingSignal>[];
      final sub = cubit.signalStream.listen(signals.add);
      cubit.selectSlot(at(12, 12));

      final first = cubit.book();
      await cubit.book();

      expect(cubit.state.isSaving, isTrue);
      expect(cubit.state.canBook, isFalse);
      write.complete(appointment('a', at(12, 12)));
      await first;
      await settle();

      verify(
        () => appointments.book(
          clientId: any(named: 'clientId'),
          startsAt: any(named: 'startsAt'),
          isTimeFixed: any(named: 'isTimeFixed'),
        ),
      ).called(1);
      expect(signals, [BookingSignal.booked]);
      await sub.cancel();
    });

    test('does nothing without a picked hour', () async {
      await load();

      await cubit.book();

      verifyNever(
        () => appointments.book(
          clientId: any(named: 'clientId'),
          startsAt: any(named: 'startsAt'),
          isTimeFixed: any(named: 'isTimeFixed'),
        ),
      );
    });

    test('a failure goes to the error channel', () async {
      when(
        () => appointments.book(
          clientId: any(named: 'clientId'),
          startsAt: any(named: 'startsAt'),
          isTimeFixed: any(named: 'isTimeFixed'),
        ),
      ).thenThrow(const AppointmentValidationException(AppointmentValidationError.inPast));
      await load();
      final errors = <Object>[];
      final sub = cubit.errorStream.listen(errors.add);
      cubit.selectSlot(at(12, 12));

      await cubit.book();
      await settle();

      expect(errors.single, isA<LocalizedAppointmentInPastException>());
      expect(cubit.state.isSaving, isFalse);
      await sub.cancel();
    });
  });

  group('cancel', () {
    test('cancels the open booking and signals the page', () async {
      when(
        () => appointments.setStatus('own', AppointmentStatus.cancelled),
      ).thenAnswer((_) async {});
      await load(booking: appointment('own', at(13, 9)));
      final signals = <BookingSignal>[];
      final sub = cubit.signalStream.listen(signals.add);

      await cubit.cancel();
      await settle();

      verify(() => appointments.setStatus('own', AppointmentStatus.cancelled)).called(1);
      expect(signals, [BookingSignal.cancelled]);
      await sub.cancel();
    });

    test('a second tap while the first write runs cancels once', () async {
      final write = Completer<void>();
      when(
        () => appointments.setStatus('own', AppointmentStatus.cancelled),
      ).thenAnswer((_) => write.future);
      await load(booking: appointment('own', at(13, 9)));

      final first = cubit.cancel();
      await cubit.cancel();
      write.complete();
      await first;

      verify(() => appointments.setStatus('own', AppointmentStatus.cancelled)).called(1);
    });

    test('does nothing without an open booking', () async {
      await load();

      await cubit.cancel();

      verifyNever(() => appointments.setStatus(any(), any()));
    });

    test('a failure goes to the error channel', () async {
      when(
        () => appointments.setStatus('own', AppointmentStatus.cancelled),
      ).thenThrow(const AppointmentNotFoundException('own'));
      await load(booking: appointment('own', at(13, 9)));
      final errors = <Object>[];
      final sub = cubit.errorStream.listen(errors.add);

      await cubit.cancel();
      await settle();

      expect(errors.single, isA<LocalizedAppointmentNotFoundException>());
      await sub.cancel();
    });
  });
}
