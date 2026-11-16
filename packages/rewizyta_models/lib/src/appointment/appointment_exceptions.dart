/// Thrown when an appointment id does not exist locally.
final class const AppointmentNotFoundException(final String id) implements Exception {
  @override
  String toString() => 'AppointmentNotFoundException($id)';
}

/// Thrown when an appointment cannot be saved.
final class const AppointmentValidationException(final AppointmentValidationError error)
    implements Exception {
  @override
  String toString() => 'AppointmentValidationException($error)';
}

/// Field-level validation outcomes. Localized in the view-model layer.
enum AppointmentValidationError() {
  /// The booked hour has already passed.
  inPast,
}
