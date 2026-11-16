import 'package:rewizyta_models/src/appointment/appointment.dart';
import 'package:rewizyta_models/src/planner/planner_settings.dart';

/// The hours of [day] (a local calendar day; its time and zone are ignored)
/// that a new booking can take, as UTC instants.
///
/// The grid starts at the working hours' start and steps by
/// [PlannerSettings.slotMinutes] while a slot still ends by the working hours'
/// end. [taken] is what is
/// already on the day: cancelled and deleted rows are ignored, and the caller
/// leaves out a booking that is being moved. A slot is free when it overlaps
/// none of them (by interval, because durations differ); a day whose
/// [taken] already fills [PlannerSettings.slotsPerDay] has no free slot, so the
/// capacity wins over the grid. Slots at or before [notBefore] are dropped.
List<DateTime> freeSlots({
  required DateTime day,
  required PlannerSettings settings,
  required Iterable<Appointment> taken,
  required DateTime notBefore,
}) {
  final busy = [
    for (final appointment in taken)
      if (appointment.status != AppointmentStatus.cancelled && !appointment.isDeleted)
        (
          start: appointment.startsAt.toUtc(),
          end: appointment.startsAt.toUtc().add(Duration(minutes: appointment.durationMinutes)),
        ),
  ];
  if (busy.length >= settings.slotsPerDay) {
    return const [];
  }
  final slotLength = Duration(minutes: settings.slotMinutes);
  final slots = <DateTime>[];
  for (
    var minutes = settings.workStartMinutes;
    minutes + settings.slotMinutes <= settings.workEndMinutes;
    minutes += settings.slotMinutes
  ) {
    // Built from the local wall clock, never as midnight plus a Duration,
    // which lands an hour off on a DST day.
    final start = DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60).toUtc();
    final end = start.add(slotLength);
    final isTaken = busy.any((b) => start.isBefore(b.end) && b.start.isBefore(end));
    if (!isTaken && start.isAfter(notBefore.toUtc())) {
      slots.add(start);
    }
  }
  return slots;
}
