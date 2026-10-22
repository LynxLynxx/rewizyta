/// Thrown when an equipment id does not exist locally.
final class const EquipmentNotFoundException(final String id) implements Exception {
  @override
  String toString() => 'EquipmentNotFoundException($id)';
}

/// Thrown when equipment cannot be saved because a field is invalid.
final class const EquipmentValidationException(final EquipmentValidationError error)
    implements Exception {
  @override
  String toString() => 'EquipmentValidationException($error)';
}

/// Field-level validation outcomes. Localized in the view-model layer.
enum EquipmentValidationError() {
  countBelowOne,
}
