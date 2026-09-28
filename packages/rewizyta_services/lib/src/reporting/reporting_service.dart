/// Crash and error reporting behind a vendor-agnostic interface.
///
/// The chosen vendor is Sentry with EU data residency (or a self-hosted
/// GlitchTip, which speaks the same protocol); the no-op implementation is the
/// fallback. The global BlocObserver and the Flutter error handlers forward
/// here in every build mode.
abstract interface class ReportingService() {
  Future<void> init();

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  });

  void log(String message);

  void setUserIdentifier(String? id);

  void setCustomKey(String key, Object value);

  Future<void> setEnabled({required bool enabled});
}
