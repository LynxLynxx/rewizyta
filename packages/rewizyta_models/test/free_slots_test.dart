import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2026, 11);
  final day = DateTime(2026, 11, 12);
  const settings = PlannerSettings();
  final longAgo = DateTime.utc(2000);

  DateTime at(int hour, [int minute = 0]) => DateTime(2026, 11, 12, hour, minute).toUtc();

  Appointment booked(
    int hour, {
    int minutes = 60,
    AppointmentStatus status = AppointmentStatus.planned,
    DateTime? deletedAt,
  }) => Appointment(
    id: 'a$hour',
    clientId: 'c',
    startsAt: at(hour),
    durationMinutes: minutes,
    status: status,
    createdAt: t0,
    updatedAt: t0,
    deletedAt: deletedAt,
  );

  List<DateTime> free(
    Iterable<Appointment> taken, {
    PlannerSettings s = settings,
    DateTime? notBefore,
  }) => freeSlots(day: day, settings: s, taken: taken, notBefore: notBefore ?? longAgo);

  test('an empty day offers the grid from the working hours', () {
    expect(free(const []), [for (var h = 8; h < 16; h++) at(h)]);
  });

  test('slots are the local wall clock, whatever the zone and the day', () {
    for (final slot in free(const [])) {
      final local = slot.toLocal();
      expect((local.year, local.month, local.day), (2026, 11, 12));
      expect(local.minute, 0);
    }
  });

  test('a booking blocks every slot it overlaps, by interval', () {
    expect(free([booked(9, minutes: 90)]), [at(8), for (var h = 11; h < 16; h++) at(h)]);
  });

  test('a booking that starts mid-slot blocks that slot', () {
    final half = Appointment(
      id: 'half',
      clientId: 'c',
      startsAt: at(9, 30),
      durationMinutes: 30,
      createdAt: t0,
      updatedAt: t0,
    );
    expect(free([half]), isNot(contains(at(9))));
    expect(free([half]), contains(at(10)));
  });

  test('done and no-show bookings take a slot, cancelled and deleted ones do not', () {
    expect(free([booked(8, status: AppointmentStatus.done)]), isNot(contains(at(8))));
    expect(free([booked(8, status: AppointmentStatus.noShow)]), isNot(contains(at(8))));
    expect(free([booked(8, status: AppointmentStatus.cancelled)]), contains(at(8)));
    expect(free([booked(8, deletedAt: t0)]), contains(at(8)));
  });

  test('a day with slots_per_day bookings has no free slot', () {
    const small = PlannerSettings(slotsPerDay: 2);
    expect(free([booked(8), booked(9)], s: small), isEmpty);
    expect(free([booked(8)], s: small), isNotEmpty);
  });

  test('the grid steps by the slot length and ends by the working hours', () {
    expect(free(const [], s: const PlannerSettings(slotMinutes: 120, workEndMinutes: 17 * 60)), [
      at(8),
      at(10),
      at(12),
      at(14),
    ]);
  });

  test('slots keep the local wall clock on the days the clocks change', () {
    for (final changeDay in [DateTime(2026, 3, 29), DateTime(2026, 10, 25)]) {
      final slots = freeSlots(
        day: changeDay,
        settings: settings,
        taken: const [],
        notBefore: longAgo,
      );

      expect(slots.map((slot) => slot.toLocal().hour), [for (var h = 8; h < 16; h++) h]);
      expect(slots.map((slot) => slot.toLocal().day).toSet(), {changeDay.day});
    }
  });

  test('slots at or before now are dropped', () {
    expect(free(const [], notBefore: at(10)).first, at(11));
    expect(free(const [], notBefore: at(16)), isEmpty);
  });
}
