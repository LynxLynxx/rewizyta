import 'package:equatable/equatable.dart';
import 'package:rewizyta_models/src/appointment/appointment.dart';
import 'package:rewizyta_models/src/client/client.dart';
import 'package:rewizyta_models/src/planner/planner_settings.dart';
import 'package:rewizyta_models/src/planner/road_distance.dart';

/// One appointment of the day, with the client it is at.
final class const DayStop({required final Appointment appointment, required final Client client})
    with Equatable {
  /// The client's coordinates, or null until both are known.
  LatLng? get location {
    final lat = client.lat;
    final lng = client.lng;
    return lat == null || lng == null ? null : (lat: lat, lng: lng);
  }

  /// The optimiser leaves the stop at its place in start order: the client
  /// asked for the hour, or the visit is already done or missed.
  bool get isPinned => appointment.isTimeFixed || appointment.status != AppointmentStatus.planned;

  @override
  List<Object?> get props => [appointment, client];
}

/// A day's stops in route order and what the planner derives from them
/// (docs/TRD.md, "Day planning"). Cancelled appointments are never in it;
/// done and no-show ones are, and take a slot.
final class const DayPlan({
  required final List<DayStop> stops,
  required final PlannerSettings settings,
}) with Equatable {
  /// The day as stored: cancelled stops dropped, ordered by `route_position`
  /// (unordered ones last), then by start, then by id.
  factory of(Iterable<DayStop> stops, PlannerSettings settings) => DayPlan(
    stops: [
      for (final stop in stops)
        if (stop.appointment.status != AppointmentStatus.cancelled) stop,
    ]..sort(_byPosition),
    settings: settings,
  );

  /// Estimated road km to stop [index] from the stop before it (from home for
  /// the first); null when either end has no coordinates.
  double? legKm(int index) =>
      _km(index == 0 ? settings.home : stops[index - 1].location, stops[index].location);

  /// The known legs plus the way home from the last stop.
  double get totalKm => [
    for (var i = 0; i < stops.length; i++) legKm(i) ?? 0,
    if (stops.isNotEmpty) _km(stops.last.location, settings.home) ?? 0,
  ].fold(0, (sum, km) => sum + km);

  int get travelMinutes => (totalKm * 60 / settings.travelSpeedKmh).round();

  int get visitMinutes => stops.fold(0, (sum, stop) => sum + stop.appointment.durationMinutes);

  /// Negative when the day is overbooked.
  int get slotsLeft => settings.slotsPerDay - stops.length;

  /// Whether the visits and the estimated travel fit in the working hours.
  bool get fitsWorkingHours =>
      visitMinutes + travelMinutes <= settings.workEndMinutes - settings.workStartMinutes;

  /// The stops in nearest-neighbour order.
  ///
  /// Pinned stops ([DayStop.isPinned]) keep their place in start order. Every
  /// other place takes the flexible stop nearest to the last known location,
  /// starting from home, or without one from the earliest located stop. A stop
  /// without coordinates counts as infinitely far, so such stops come last;
  /// ties go to the earlier start, then the lower id. Greedy and O(n²) with no
  /// lookahead: fine for a day's handful of stops, not an optimal tour.
  DayPlan optimised() {
    final byStart = [...stops]..sort(_byStart);
    final flexible = [
      for (final stop in byStart)
        if (!stop.isPinned) stop,
    ];
    final route = <DayStop>[];
    var from = settings.home;
    for (final stop in byStart) {
      final next = stop.isPinned ? stop : _nearest(flexible, from);
      flexible.remove(next);
      route.add(next);
      from = next.location ?? from;
    }
    return DayPlan(stops: route, settings: settings);
  }

  @override
  List<Object?> get props => [stops, settings];
}

double? _km(LatLng? from, LatLng? to) => from == null || to == null ? null : roadKm(from, to);

/// The first of [candidates] (in start order) at the smallest distance. A stop
/// without coordinates is infinitely far; with no [from] yet every located
/// stop is equally near.
DayStop _nearest(List<DayStop> candidates, LatLng? from) {
  double distance(DayStop stop) {
    final to = stop.location;
    if (to == null) return double.infinity;
    return from == null ? 0 : roadKm(from, to);
  }

  return candidates.reduce((best, stop) => distance(stop) < distance(best) ? stop : best);
}

int _byStart(DayStop a, DayStop b) {
  final byTime = a.appointment.startsAt.compareTo(b.appointment.startsAt);
  return byTime != 0 ? byTime : a.appointment.id.compareTo(b.appointment.id);
}

int _byPosition(DayStop a, DayStop b) {
  final pa = a.appointment.routePosition;
  final pb = b.appointment.routePosition;
  if (pa == pb) return _byStart(a, b);
  if (pa == null) return 1;
  if (pb == null) return -1;
  return pa.compareTo(pb);
}
