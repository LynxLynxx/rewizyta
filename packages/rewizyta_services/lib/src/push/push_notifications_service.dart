/// A push message delivered to this device.
final class const PushMessage({
  required final String title,
  required final String body,
  final Map<String, String> data = const {},
});

/// Push notifications behind a vendor-agnostic interface.
///
/// Android delivery realistically needs FCM (Google); the adapter keeps that
/// choice in one place so a self-hoster can plug in UnifiedPush/ntfy. The
/// device token is stored server-side in `devices` and used by edge functions;
/// the phone never addresses another device.
abstract interface class PushNotificationsService() {
  Future<void> init();

  /// Asks the OS for permission (Android 13+, iOS). Returns whether granted.
  Future<bool> requestPermission();

  /// Current registration token, null until the vendor SDK issues one.
  Future<String?> getToken();

  /// Emits whenever the token rotates; the sync layer uploads it.
  Stream<String> get onTokenRefresh;

  /// Foreground messages. Background taps come through [onMessageOpened].
  Stream<PushMessage> get onMessage;

  Stream<PushMessage> get onMessageOpened;

  Future<void> deleteToken();
}
