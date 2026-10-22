/// Thrown when a visit id does not exist locally.
final class const VisitNotFoundException(final String id) implements Exception {
  @override
  String toString() => 'VisitNotFoundException($id)';
}

/// Thrown when a visit cannot be saved because a field is invalid.
final class const VisitValidationException(final VisitValidationError error) implements Exception {
  @override
  String toString() => 'VisitValidationException($error)';
}

/// Field-level validation outcomes. Localized in the view-model layer.
enum VisitValidationError() {
  priceNegative,
}
