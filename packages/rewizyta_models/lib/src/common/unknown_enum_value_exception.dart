/// Thrown when a stored or pulled row holds an enum value this build does not
/// know, e.g. a status or `template_key` added by a newer release. The sync
/// pull skips and reports such a row instead of storing it
/// (docs/BACKEND_SCHEMA.md, "A new enumeration value is an app change first").
final class const UnknownEnumValueException(final Type enumType, final String value)
    implements Exception {
  @override
  String toString() => 'UnknownEnumValueException($enumType, $value)';
}
