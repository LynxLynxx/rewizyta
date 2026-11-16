import 'package:rewizyta_models/rewizyta_models.dart';

/// Booking a client and moving the booking through its statuses
/// (docs/BACKEND_SCHEMA.md, "appointments").
abstract interface class AppointmentsService() {
  /// The client's open booking as it changes: the earliest planned appointment
  /// from local midnight today on, or null.
  Stream<Appointment?> watchOpenBooking(String clientId);

  /// Books [clientId] at [startsAt]. A client has one open booking, so an
  /// existing one is moved (its route position is cleared, because the day
  /// changed); otherwise a planned appointment of the planner's slot length is
  /// created. [isTimeFixed] pins the hour against the route optimiser.
  /// Throws [AppointmentValidationException] when [startsAt] has passed.
  Future<Appointment> book({
    required String clientId,
    required DateTime startsAt,
    bool isTimeFixed = false,
  });

  /// Sets the status, for cancelling or marking a no-show. Done is set by
  /// `VisitsService`, with the visit. Throws [AppointmentNotFoundException]
  /// for an unknown [id].
  Future<void> setStatus(String id, AppointmentStatus status);
}
