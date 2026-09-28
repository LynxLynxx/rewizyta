import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

abstract interface class SignalEmitter<Signal extends Object>() {
  Stream<Signal> get signalStream;
}

/// One-off effects (navigate, toast, open a sheet) leave the cubit through
/// this channel. State is what the UI *is*; a signal is what just happened.
mixin BlocSignalEmitterMixin<Signal extends Object, State> on BlocBase<State>
    implements SignalEmitter<Signal> {
  late final _signalController = StreamController<Signal>.broadcast();

  @override
  Stream<Signal> get signalStream => _signalController.stream;

  @protected
  void emitSignal(Signal signal) {
    if (isClosed) return;
    _signalController.add(signal);
  }

  @override
  Future<void> close() async {
    await _signalController.close();
    await super.close();
  }
}
