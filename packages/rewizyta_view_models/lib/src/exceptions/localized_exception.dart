import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_models/rewizyta_models.dart';

/// Turns a typed domain exception into user-facing text. Cubits call
/// [LocalizedException.create] at the catch site and push the result through
/// the error side-channel; the page renders it as a snackbar.
///
/// When a new typed exception is added to rewizyta_models, add its localized
/// counterpart and a branch in `LocalizedException.create` in the same change.
abstract base class const LocalizedException() with Equatable implements Exception {
  factory create(Object error) {
    if (error is LocalizedException) return error;
    if (error is ClientNotFoundException) return const LocalizedClientNotFoundException();
    return LocalizedUnknownException(cause: error);
  }

  String message(BuildContext context);

  String title(BuildContext context) => context.l10n.errorGenericTitle;

  @override
  List<Object?> get props => const [];

  @override
  String toString() {
    final fields = props.where((p) => p != null).join(', ');
    return fields.isEmpty ? '$runtimeType' : '$runtimeType($fields)';
  }
}

final class const LocalizedClientNotFoundException() extends LocalizedException {
  @override
  String message(BuildContext context) => context.l10n.errorClientNotFound;
}

/// Fallback. The page swallows it (logged and reported instead of shown), so
/// every intentional error path needs a real subclass above.
final class const LocalizedUnknownException({required final Object cause})
    extends LocalizedException {
  @override
  String message(BuildContext context) => context.l10n.errorGenericTitle;

  @override
  List<Object?> get props => [cause];
}
