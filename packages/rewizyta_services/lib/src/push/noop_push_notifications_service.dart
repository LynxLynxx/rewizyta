import 'package:rewizyta_services/src/push/push_notifications_service.dart';

final class const NoopPushNotificationsService() implements PushNotificationsService {
  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<PushMessage> get onMessage => const Stream.empty();

  @override
  Stream<PushMessage> get onMessageOpened => const Stream.empty();

  @override
  Future<void> deleteToken() async {}
}
