/// Thrown when a trade cannot be saved because a field is invalid.
final class const TradeValidationException(final TradeValidationError error) implements Exception {
  @override
  String toString() => 'TradeValidationException($error)';
}

/// Field-level validation outcomes. Localized in the view-model layer.
enum TradeValidationError() {
  nameEmpty,
}
