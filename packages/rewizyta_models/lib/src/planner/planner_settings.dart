import 'package:equatable/equatable.dart';
import 'package:rewizyta_models/src/planner/road_distance.dart';

/// The day planner's settings from `profiles`, with the schema's defaults
/// (docs/BACKEND_SCHEMA.md). Working hours are minutes since midnight. Without
/// a [home] the day starts at its first located stop.
final class const PlannerSettings({
  final LatLng? home,
  final int workStartMinutes = 8 * 60,
  final int workEndMinutes = 16 * 60,
  final int slotsPerDay = 8,
  final int travelSpeedKmh = 40,
}) with Equatable {
  this : assert(travelSpeedKmh > 0, 'The travel speed divides the distance');

  @override
  List<Object?> get props => [home, workStartMinutes, workEndMinutes, slotsPerDay, travelSpeedKmh];
}
