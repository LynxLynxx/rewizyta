/// Thrown when a client id does not exist locally.
final class const ClientNotFoundException(final String id) implements Exception {
  @override
  String toString() => 'ClientNotFoundException($id)';
}

/// Thrown when a client cannot be saved because a required field is empty.
final class const ClientValidationException(final ClientValidationError error)
    implements Exception {
  @override
  String toString() => 'ClientValidationException($error)';
}

/// Field-level validation outcomes. Localized in the view-model layer.
enum ClientValidationError() {
  nameEmpty,
  phoneInvalid,
}
