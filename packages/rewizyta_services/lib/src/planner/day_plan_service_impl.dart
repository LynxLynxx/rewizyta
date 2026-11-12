import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:rewizyta_services/src/planner/day_plan_service.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';

/// The settings are the schema defaults until `profiles` reaches the phone (M5)
/// and gets an editor (M7).
final class DayPlanServiceImpl(
  final AppointmentsRepository _appointments,
  final TransactionRunner _transaction, {
  PlannerSettings settings = const PlannerSettings(),
  DateTime Function()? now,
}) implements DayPlanService {
  final PlannerSettings _settings = settings;
  final DateTime Function() _now = now ?? DateTime.timestamp;

  @override
  Stream<DayPlan> watchDay(DateTime day) {
    final (from, to) = _bounds(day);
    return _appointments.watchStopsBetween(from, to).map((stops) => DayPlan.of(stops, _settings));
  }

  @override
  Future<void> optimiseDay(DateTime day) => _write(day, (plan) => plan.optimised());

  @override
  Future<void> reorder(DateTime day, List<String> appointmentIds) => _write(day, (plan) {
    final byId = {for (final stop in plan.stops) stop.appointment.id: stop};
    return DayPlan(
      stops: [for (final id in appointmentIds) ?byId.remove(id), ...byId.values],
      settings: _settings,
    );
  });

  /// Reads [day]'s plan and saves [order]'s result as route positions in one
  /// transaction: nothing when the order is the stored one, otherwise only the
  /// stops whose position changes.
  Future<void> _write(DateTime day, DayPlan Function(DayPlan plan) order) {
    final (from, to) = _bounds(day);
    final now = _now();
    return _transaction.run(() async {
      final plan = DayPlan.of(await _appointments.findStopsBetween(from, to), _settings);
      final next = order(plan);
      if (next == plan) {
        return;
      }
      for (final (index, stop) in next.stops.indexed) {
        final appointment = stop.appointment;
        if (appointment.routePosition != index) {
          await _appointments.upsert(
            appointment.copyWith(routePosition: Optional(index), updatedAt: now),
          );
        }
      }
    });
  }

  /// Local midnight of [day]'s date to the next local midnight, 23 or 25 hours
  /// apart on a DST change. The repository compares them as UTC instants.
  (DateTime, DateTime) _bounds(DateTime day) =>
      (DateTime(day.year, day.month, day.day), DateTime(day.year, day.month, day.day + 1));
}
