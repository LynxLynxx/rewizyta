import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2026, 11);
  const home = (lat: 0.0, lng: 0.0);

  /// Appointment [id] at [hour] (08:00 unless given) on 12 November, at a client of its own.
  DayStop stop(
    String id, {
    int hour = 8,
    double? lat,
    double? lng,
    bool fixed = false,
    AppointmentStatus status = AppointmentStatus.planned,
    int? position,
  }) => DayStop(
    appointment: Appointment(
      id: id,
      clientId: 'c-$id',
      startsAt: DateTime.utc(2026, 11, 12, hour),
      status: status,
      isTimeFixed: fixed,
      routePosition: position,
      createdAt: t0,
      updatedAt: t0,
    ),
    client: Client(id: 'c-$id', name: id, lat: lat, lng: lng, createdAt: t0, updatedAt: t0),
  );

  /// A stop on the equator; 0.1° of longitude is about 14.455 road km.
  DayStop onEquator(
    String id,
    int hour,
    double lng, {
    bool fixed = false,
    AppointmentStatus status = AppointmentStatus.planned,
  }) => stop(id, hour: hour, lat: 0, lng: lng, fixed: fixed, status: status);

  List<String> ids(DayPlan plan) => [for (final stop in plan.stops) stop.appointment.id];
  List<double?> legs(DayPlan plan) => [for (var i = 0; i < plan.stops.length; i++) plan.legKm(i)];

  group('roadKm', () {
    test('is the haversine distance times the road factor', () {
      expect(roadKm(home, (lat: 0, lng: 1)), closeTo(144.553, 0.001));
      expect(roadKm(home, (lat: 1, lng: 0)), closeTo(144.553, 0.001));
      expect(roadKm((lat: 50, lng: 20), (lat: 50, lng: 21)), closeTo(92.916, 0.001));
    });

    test('is symmetric and zero for the same point', () {
      const a = (lat: 50.06, lng: 19.94);
      const b = (lat: 49.3, lng: 19.95);
      expect(roadKm(a, b), closeTo(roadKm(b, a), 1e-9));
      expect(roadKm(a, a), 0);
    });
  });

  group('PlannerSettings', () {
    test('defaults to the schema defaults', () {
      const settings = PlannerSettings();
      expect(
        (
          settings.home,
          settings.workStartMinutes,
          settings.workEndMinutes,
          settings.slotsPerDay,
          settings.travelSpeedKmh,
        ),
        (null, 8 * 60, 16 * 60, 8, 40),
      );
    });

    test('rejects a travel speed below 1 km/h', () {
      expect(() => PlannerSettings(travelSpeedKmh: 0), throwsA(isA<AssertionError>()));
    });
  });

  group('DayStop', () {
    test('has a location only when the client has both coordinates', () {
      expect(stop('a', lat: 50, lng: 20).location, (lat: 50.0, lng: 20.0));
      expect(stop('a', lat: 50).location, isNull);
      expect(stop('a', lng: 20).location, isNull);
    });

    test('is pinned when the time is fixed or the visit is done or missed', () {
      expect(stop('a').isPinned, isFalse);
      expect(stop('a', fixed: true).isPinned, isTrue);
      expect(stop('a', status: AppointmentStatus.done).isPinned, isTrue);
      expect(stop('a', status: AppointmentStatus.noShow).isPinned, isTrue);
    });
  });

  group('DayPlan.of', () {
    test('drops cancelled stops and orders by position, unordered last by start', () {
      final plan = DayPlan.of([
        stop('late', hour: 12),
        stop('x', position: 1),
        stop('early', hour: 9),
        stop('gone', status: AppointmentStatus.cancelled, position: 0),
        stop('y', hour: 10, position: 0),
      ], const PlannerSettings());

      expect(ids(plan), ['y', 'x', 'early', 'late']);
    });

    test('orders equal positions by start, then by id', () {
      final plan = DayPlan.of([
        stop('b', hour: 9, position: 1),
        stop('a', hour: 9, position: 1),
        stop('c', hour: 11, position: 0),
        stop('d', position: 1),
      ], const PlannerSettings());

      expect(ids(plan), ['c', 'd', 'a', 'b']);
    });
  });

  group('a day on the equator', () {
    final stored = DayPlan.of([
      onEquator('A', 8, 0.3),
      onEquator('F', 9, 0.5, fixed: true),
      onEquator('B', 10, 0.1),
      onEquator('C', 11, 0.2),
    ], const PlannerSettings(home: home));

    test('as stored, measures the start order and its way home', () {
      expect(ids(stored), ['A', 'F', 'B', 'C']);
      expect(stored.totalKm, closeTo(173.464, 0.001));
      expect(stored.travelMinutes, 260);
      expect(stored.visitMinutes, 240);
      expect(stored.fitsWorkingHours, isFalse);
      expect(stored.slotsLeft, 4);
    });

    test('optimised keeps the fixed stop at its place and fills the rest by nearest', () {
      final optimised = stored.optimised();

      expect(ids(optimised), ['B', 'F', 'A', 'C']);
      expect(legs(optimised), [
        closeTo(14.455, 0.001),
        closeTo(57.821, 0.001),
        closeTo(28.911, 0.001),
        closeTo(14.455, 0.001),
      ]);
      expect(optimised.totalKm, closeTo(144.553, 0.001));
      expect(optimised.travelMinutes, 217);
      expect(optimised.fitsWorkingHours, isTrue);
    });

    for (final status in [AppointmentStatus.done, AppointmentStatus.noShow]) {
      test('optimised keeps a ${status.name} stop at its place', () {
        final plan = DayPlan.of([
          onEquator('A', 8, 0.3),
          onEquator('F', 9, 0.5, status: status),
          onEquator('B', 10, 0.1),
          onEquator('C', 11, 0.2),
        ], const PlannerSettings(home: home));

        expect(ids(plan.optimised()), ['B', 'F', 'A', 'C']);
      });
    }
  });

  group('optimised off the line', () {
    final stops = [
      stop('p', lat: 0, lng: 0.3),
      stop('q', hour: 9, lat: 0.1, lng: 0.05),
      stop('r', hour: 10, lat: 0, lng: -0.15),
      stop('s', hour: 11, lat: 0.12, lng: 0.3),
      stop('t', hour: 12, lat: 0.05, lng: 0.2),
    ];
    const settings = PlannerSettings(home: home);

    test('shortens the start order when every stop is flexible', () {
      final plan = DayPlan.of(stops, settings);
      final optimised = plan.optimised();

      expect(plan.totalKm, closeTo(229.379, 0.001));
      expect(ids(optimised), ['q', 't', 'p', 's', 'r']);
      expect(optimised.totalKm, closeTo(161.531, 0.001));
    });

    test('keeps a fixed stop at its place in start order', () {
      final withFixed = [
        for (final s in stops)
          if (s.appointment.id == 'r')
            DayStop(appointment: s.appointment.copyWith(isTimeFixed: true), client: s.client)
          else
            s,
      ];

      final optimised = DayPlan.of(withFixed, settings).optimised();

      expect(ids(optimised), ['q', 't', 'r', 'p', 's']);
      expect(optimised.totalKm, closeTo(219.227, 0.001));
    });
  });

  test('optimised breaks distance ties by start, then by id', () {
    final plan = DayPlan.of([
      onEquator('far', 8, 0.5),
      onEquator('b', 10, 0.1),
      onEquator('a', 10, 0.1),
      onEquator('c', 9, 0.1),
    ], const PlannerSettings(home: home));

    expect(ids(plan.optimised()), ['c', 'a', 'b', 'far']);
  });

  test('optimised puts stops without coordinates last, and only known legs count', () {
    final plan = DayPlan.of([
      stop('x'),
      onEquator('y', 9, 0.1),
      stop('z', hour: 10),
      onEquator('w', 11, 0.2),
    ], const PlannerSettings(home: home));

    final optimised = plan.optimised();

    expect(ids(optimised), ['y', 'w', 'x', 'z']);
    expect(legs(optimised), [closeTo(14.455, 0.001), closeTo(14.455, 0.001), null, null]);
    expect(optimised.totalKm, closeTo(28.911, 0.001));
  });

  test('without home, optimised starts at the earliest stop and has no way home', () {
    final plan = DayPlan.of([
      onEquator('a', 8, 0.3),
      onEquator('b', 9, 0.1),
      onEquator('c', 10, 0.25),
    ], const PlannerSettings());

    final optimised = plan.optimised();

    expect(ids(optimised), ['a', 'c', 'b']);
    expect(legs(optimised), [null, closeTo(7.228, 0.001), closeTo(21.683, 0.001)]);
    expect(optimised.totalKm, closeTo(28.911, 0.001));
  });

  test('without home, an earlier stop without coordinates still comes last', () {
    final plan = DayPlan.of([
      stop('x'),
      onEquator('y', 9, 0.3),
      onEquator('z', 10, 0.1),
    ], const PlannerSettings());

    expect(ids(plan.optimised()), ['y', 'z', 'x']);
  });

  test('without any coordinates, optimised is the start order and travel is zero', () {
    final plan = DayPlan.of([
      stop('a', position: 2),
      stop('b', hour: 9, position: 1),
      stop('c', hour: 10, position: 0),
    ], const PlannerSettings(home: home));

    final optimised = plan.optimised();

    expect(ids(plan), ['c', 'b', 'a']);
    expect(ids(optimised), ['a', 'b', 'c']);
    expect((optimised.totalKm, optimised.travelMinutes), (0, 0));
  });

  test('an empty day has every slot left and fits', () {
    final plan = DayPlan.of(const [], const PlannerSettings());

    expect(plan.stops, isEmpty);
    expect((plan.slotsLeft, plan.totalKm, plan.fitsWorkingHours), (8, 0, true));
    expect(plan.optimised(), plan);
  });

  test('a single stop stays and its way there and back counts', () {
    final plan = DayPlan.of([onEquator('a', 8, 0.1)], const PlannerSettings(home: home));

    expect(plan.optimised(), plan);
    expect(plan.totalKm, closeTo(28.911, 0.001));
  });

  group('capacity', () {
    test('slotsLeft goes negative when the day is overbooked', () {
      final plan = DayPlan.of([
        for (var i = 0; i < 4; i++) stop('s$i', hour: 8 + i),
      ], const PlannerSettings(slotsPerDay: 3));

      expect(plan.slotsLeft, -1);
    });

    test('visits alone can overflow the working hours', () {
      DayPlan day(int visits) => DayPlan.of([
        for (var i = 0; i < visits; i++) stop('s$i', hour: 8 + i),
      ], const PlannerSettings());

      expect(day(8).fitsWorkingHours, isTrue);
      expect(day(9).visitMinutes, 540);
      expect(day(9).fitsWorkingHours, isFalse);
    });
  });
}
