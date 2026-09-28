import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

/// Named stream subscriptions cancelled automatically in [close]. Subscribing
/// again under the same key replaces the previous subscription, so rebinding
/// after a filter change is safe.
mixin SubscriptionManagerMixin<State> on BlocBase<State> {
  final _subscriptions = <Symbol, StreamSubscription<dynamic>>{};

  @protected
  void subscribe<T>(
    Symbol key,
    Stream<T> stream,
    void Function(T data) onData, {
    Function? onError,
  }) {
    unawaited(_subscriptions[key]?.cancel());
    _subscriptions[key] = stream.listen(onData, onError: onError);
  }

  @protected
  void cancelSubscription(Symbol key) {
    unawaited(_subscriptions.remove(key)?.cancel());
  }

  @override
  Future<void> close() {
    for (final sub in _subscriptions.values) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
    return super.close();
  }
}
