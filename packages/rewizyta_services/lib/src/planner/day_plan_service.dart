import 'package:rewizyta_models/rewizyta_models.dart';

/// The day planner: a day's stops as a [DayPlan] and the writes that order
/// them (`appointments.route_position`, 0-based within the local day). The
/// rules live in [DayPlan]; this reads and persists.
abstract interface class DayPlanService() {
  /// The plan of [day] as it changes. Every method takes [day]'s year, month
  /// and day as a local calendar day, local midnight to local midnight; its
  /// time and zone are ignored.
  Stream<DayPlan> watchDay(DateTime day);

  /// "Ułóż trasę najkrócej": writes [DayPlan.optimised]'s order to the route
  /// positions. Writes nothing when the order would not change.
  Future<void> optimiseDay(DateTime day);

  /// Drag-and-drop: writes [appointmentIds]' order to the route positions.
  /// Unknown or duplicate ids are ignored; the day's stops missing from the
  /// list follow in their current order.
  Future<void> reorder(DateTime day, List<String> appointmentIds);
}
