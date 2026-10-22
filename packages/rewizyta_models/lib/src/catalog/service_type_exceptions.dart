/// Thrown when a service type id does not exist locally.
final class const ServiceTypeNotFoundException(final String id) implements Exception {
  @override
  String toString() => 'ServiceTypeNotFoundException($id)';
}

/// Thrown when a service type cannot be saved because a field is invalid.
final class const ServiceTypeValidationException(final ServiceTypeValidationError error)
    implements Exception {
  @override
  String toString() => 'ServiceTypeValidationException($error)';
}

/// Field-level validation outcomes. Localized in the view-model layer.
enum ServiceTypeValidationError() {
  cycleBelowOne,
}
