import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// Subscribes a page's `_View` state to its cubit's error channel and renders
/// localized errors as a snackbar. Unknown errors are swallowed here: they are
/// already logged and reported, and "unknown error" tells the user nothing.
mixin ErrorHandlerStateMixin<E extends ErrorEmitter, T extends StatefulWidget> on State<T> {
  StreamSubscription<Object>? _errorSubscription;

  E get errorEmitter => context.read<E>();

  @override
  void initState() {
    super.initState();
    _errorSubscription = errorEmitter.errorStream.listen(handleError);
  }

  @override
  void dispose() {
    unawaited(_errorSubscription?.cancel());
    super.dispose();
  }

  void handleError(Object error) {
    if (error is LocalizedUnknownException) return;
    if (error is LocalizedException) handleLocalizedException(error);
  }

  void handleLocalizedException(LocalizedException exception) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exception.message(context))));
  }
}
