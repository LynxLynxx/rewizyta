import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rewizyta_blocs/rewizyta_blocs.dart';

/// Subscribes a page's `_View` state to its cubit's signal channel
/// (navigation, toasts, sheets). Implement [handleSignal] with a `switch` on
/// the sealed signal type.
mixin SignalHandlerStateMixin<
  E extends SignalEmitter<Signal>,
  Signal extends Object,
  T extends StatefulWidget
>
    on State<T> {
  StreamSubscription<Signal>? _signalSubscription;

  E get signalEmitter => context.read<E>();

  void handleSignal(Signal signal);

  @override
  void initState() {
    super.initState();
    _signalSubscription = signalEmitter.signalStream.listen(handleSignal);
  }

  @override
  void dispose() {
    unawaited(_signalSubscription?.cancel());
    super.dispose();
  }
}
