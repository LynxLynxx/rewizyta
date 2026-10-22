/// Trimmed, or null when nothing is left, so an empty form field and a
/// missing value are stored the same way.
String? cleanText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
