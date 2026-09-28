import 'package:meta/meta.dart';

/// Distinguishes "not provided" from "explicitly null" in `copyWith`.
///
/// ```dart
/// state.copyWith();                                   // keep
/// state.copyWith(selected: Optional(item));           // set
/// state.copyWith(selected: const Optional.empty());   // clear
/// ```
@immutable
final class Optional<T extends Object> {
  const new(this._value) : _isPresent = true;

  const new empty() : _value = null, _isPresent = false;

  final T? _value;
  final bool _isPresent;

  bool get isPresent => _isPresent;

  T? get value => _value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Optional<T> && other._isPresent == _isPresent && other._value == _value;

  @override
  int get hashCode => Object.hash(_isPresent, _value);

  @override
  String toString() => _isPresent ? 'Optional($_value)' : 'Optional.empty()';
}

extension OptionalExtension<T extends Object> on Optional<T>? {
  /// `null` (omitted) keeps [fallback]; `Optional(v)` returns `v`;
  /// `Optional.empty()` returns `null`.
  T? dataOr(T? fallback) {
    final self = this;
    return self == null ? fallback : self._value;
  }
}
