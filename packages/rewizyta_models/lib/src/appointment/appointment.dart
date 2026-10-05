import 'package:equatable/equatable.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';

/// Where a booking stands. "Booked" in the due list means a [planned]
/// appointment from today on.
enum AppointmentStatus() {
  planned,
  done,
  cancelled,
  noShow,
}

/// A booked visit at [startsAt] (UTC).
///
/// [isTimeFixed] means the client asked for this hour and the day planner must
/// not move it. [routePosition] is the order within the day, set by the planner
/// or by drag-and-drop; null means not ordered yet.
final class const Appointment({
  required final String id,
  required final String clientId,
  required final DateTime startsAt,
  required final DateTime createdAt,
  required final DateTime updatedAt,
  final int durationMinutes = 60,
  final AppointmentStatus status = AppointmentStatus.planned,
  final bool isTimeFixed = false,
  final int? routePosition,
  final String? note,
  final DateTime? deletedAt,
}) with Equatable {
  bool get isDeleted => deletedAt != null;

  Appointment copyWith({
    DateTime? startsAt,
    int? durationMinutes,
    AppointmentStatus? status,
    bool? isTimeFixed,
    Optional<int>? routePosition,
    Optional<String>? note,
    DateTime? updatedAt,
    Optional<DateTime>? deletedAt,
  }) {
    return Appointment(
      id: id,
      clientId: clientId,
      startsAt: startsAt ?? this.startsAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      isTimeFixed: isTimeFixed ?? this.isTimeFixed,
      routePosition: routePosition.dataOr(this.routePosition),
      note: note.dataOr(this.note),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt.dataOr(this.deletedAt),
    );
  }

  @override
  List<Object?> get props => [
    id,
    clientId,
    startsAt,
    durationMinutes,
    status,
    isTimeFixed,
    routePosition,
    note,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
