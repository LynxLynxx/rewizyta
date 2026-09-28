import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rewizyta_services/rewizyta_services.dart';

/// The one global observer, installed in bootstrap. Logs transitions in debug
/// builds and forwards every error to [ReportingService] in all build modes.
final class const AppBlocObserver({
  /// `false` in tests keeps the runner output readable.
  final bool enableLogging = true,
  final ReportingService? reportingService,
}) extends BlocObserver {
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    _log('CREATE', bloc, 'created');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    _log('CHANGE', bloc, '${change.currentState} -> ${change.nextState}');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (enableLogging && kDebugMode) {
      developer.log(
        '$error',
        name: 'ERROR ${bloc.runtimeType}',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
    unawaited(
      reportingService?.recordError(error, stackTrace, reason: 'Bloc: ${bloc.runtimeType}'),
    );
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    _log('CLOSE', bloc, 'closed');
  }

  void _log(String tag, BlocBase<dynamic> bloc, String message) {
    if (!enableLogging || !kDebugMode) return;
    developer.log(message, name: '$tag ${bloc.runtimeType}', level: 500);
  }
}
