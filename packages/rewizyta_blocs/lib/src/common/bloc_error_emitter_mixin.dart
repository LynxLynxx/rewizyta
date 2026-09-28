import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

/// Read side of the error channel; the page's handler mixin listens to this.
abstract interface class ErrorEmitter() {
  Stream<Object> get errorStream;
}

/// Errors are one-shot events, not state: a dead `XError` state would throw
/// away the user's form and force a rebuild from scratch. Cubits catch, wrap
/// with `LocalizedException.create`, and [emitError]; the page shows a snackbar.
mixin BlocErrorEmitterMixin<State> on BlocBase<State> implements ErrorEmitter {
  late final _errorController = StreamController<Object>.broadcast();

  @override
  Stream<Object> get errorStream => _errorController.stream;

  @protected
  void emitError(Object error) {
    if (isClosed) return;
    _errorController.add(error);
  }

  @override
  Future<void> close() async {
    await _errorController.close();
    await super.close();
  }
}
