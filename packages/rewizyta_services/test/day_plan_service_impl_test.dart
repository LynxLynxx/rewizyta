import 'package:mocktail/mocktail.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:test/test.dart';

import 'helpers/mocks.dart';

void main() {
  final earlier = DateTime.utc(2026, 11);
  final now = DateTime.utc(2026, 11, 12, 7);
  final day = DateTime.utc(2026, 11, 12);
  final from = DateTime(2026, 11, 12);
  final to = DateTime(2026, 11, 13);
  const settings = PlannerSettings(home: (lat: 0, lng: 0));
  late MockAppointmentsRepository appointments;
  late FakeTransactionRunner transaction;
  late DayPlanServiceImpl service;

  /// Appointment [id] at [hour], at a client on the equator at [lng] (no
  /// coordinates without it).
  DayStop stop(
    String id,
    int hour, {
    double? lng,
    bool fixed = false,
    int? position,
    AppointmentStatus status = AppointmentStatus.planned,
  }) => DayStop(
    appointment: Appointment(
      id: id,
      clientId: 'c-$id',
      startsAt: DateTime.utc(2026, 11, 12, hour),
      isTimeFixed: fixed,
      routePosition: position,
      status: status,
      createdAt: earlier,
      updatedAt: earlier,
    ),
    client: Client(
      id: 'c-$id',
      name: id,
      lat: lng == null ? null : 0,
      lng: lng,
      createdAt: earlier,
      updatedAt: earlier,
    ),
  );

  void stubDay(List<DayStop> stops) =>
      when(() => appointments.findStopsBetween(from, to)).thenAnswer((_) async => stops);

  List<(String, int?, DateTime)> upserted() => [
    for (final a in verify(() => appointments.upsert(captureAny())).captured.cast<Appointment>())
      (a.id, a.routePosition, a.updatedAt),
  ];

  setUpAll(() => registerFallbackValue(stop('fallback', 8).appointment));

  setUp(() {
    appointments = MockAppointmentsRepository();
    transaction = FakeTransactionRunner();
    when(() => appointments.upsert(any())).thenAnswer((_) async {});
    service = DayPlanServiceImpl(appointments, transaction, settings: settings, now: () => now);
  });

  group('watchDay', () {
    test("emits the local day's plan with the settings, cancelled stops dropped", () async {
      final stops = [
        stop('a', 8, lng: 0.1),
        stop('gone', 9, status: AppointmentStatus.cancelled),
        stop('b', 10),
      ];
      when(() => appointments.watchStopsBetween(from, to)).thenAnswer((_) => Stream.value(stops));

      final plan = await service.watchDay(day).first;

      expect(plan, DayPlan.of(stops, settings));
      expect(plan.stops.map((s) => s.appointment.id), ['a', 'b']);
      expect(plan.settings, settings);
    });

    test('ignores the time and crosses into the next year', () async {
      final end = (DateTime(2026, 12, 31), DateTime(2027));
      when(
        () => appointments.watchStopsBetween(end.$1, end.$2),
      ).thenAnswer((_) => Stream.value(const []));

      await service.watchDay(DateTime(2026, 12, 31, 23, 59)).first;

      verify(() => appointments.watchStopsBetween(end.$1, end.$2)).called(1);
    });
  });

  group('optimiseDay', () {
    test('writes the optimised order to every stop in one transaction', () async {
      stubDay([
        stop('A', 8, lng: 0.3),
        stop('F', 9, lng: 0.5, fixed: true),
        stop('B', 10, lng: 0.1),
        stop('C', 11, lng: 0.2),
      ]);

      await service.optimiseDay(day);

      expect(transaction.runs, 1);
      expect(upserted(), [('B', 0, now), ('F', 1, now), ('A', 2, now), ('C', 3, now)]);
    });

    test('writes only the stops whose position changes', () async {
      stubDay([
        stop('A', 8, lng: 0.3, position: 3),
        stop('F', 9, lng: 0.5, fixed: true, position: 1),
        stop('B', 10, lng: 0.1, position: 0),
        stop('C', 11, lng: 0.2, position: 2),
      ]);

      await service.optimiseDay(day);

      expect(upserted(), [('A', 2, now), ('C', 3, now)]);
    });

    test('writes nothing when a gappy stored order is already the optimised one', () async {
      stubDay([stop('A', 8, lng: 0.1, position: 0), stop('B', 9, lng: 0.2, position: 5)]);

      await service.optimiseDay(day);

      verifyNever(() => appointments.upsert(any()));
    });

    test('writes nothing without coordinates while the day is unordered', () async {
      stubDay([stop('a', 8), stop('b', 9), stop('c', 10)]);

      await service.optimiseDay(day);

      expect(transaction.runs, 1);
      verifyNever(() => appointments.upsert(any()));
    });
  });

  group('reorder', () {
    final stops = [
      stop('x', 8, position: 0),
      stop('y', 9, position: 1),
      stop('z', 10, position: 2),
    ];

    test('puts the listed stops first, ignoring unknown and repeated ids', () async {
      stubDay(stops);

      await service.reorder(DateTime(2026, 11, 12, 23, 59), ['z', 'ghost', 'z']);

      expect(transaction.runs, 1);
      expect(upserted(), [('z', 0, now), ('x', 1, now), ('y', 2, now)]);
    });

    test('writes nothing for the current order', () async {
      stubDay(stops);

      await service.reorder(day, ['x', 'y', 'z']);

      verifyNever(() => appointments.upsert(any()));
    });
  });
}
