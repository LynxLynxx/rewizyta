/// One line for lists and the client card: `ul. Leśna 12, 34-400 Nowy Targ`.
/// Null when nothing of the address is known.
String? formatAddress({String? addressLine, String? postalCode, String? town}) {
  final place = [postalCode, town].nonNulls.join(' ');
  final parts = [addressLine, place].nonNulls.where((part) => part.isNotEmpty);
  return parts.isEmpty ? null : parts.join(', ');
}
