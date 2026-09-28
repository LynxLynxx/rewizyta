/// Product analytics behind a vendor-agnostic interface.
///
/// The chosen vendor is PostHog on its EU cloud (Frankfurt); a self-hoster may
/// register the no-op implementation instead. Nothing outside the DI container
/// knows which one is active. Event names are constants in the calling
/// service so that the cubits never build strings.
abstract interface class AnalyticsService() {
  Future<void> init();

  Future<void> capture(String event, {Map<String, Object?> properties = const {}});

  Future<void> screen(String name);

  Future<void> identify(String userId, {Map<String, Object?> properties = const {}});

  Future<void> reset();

  Future<void> setEnabled({required bool enabled});
}
