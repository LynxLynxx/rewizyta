import 'package:rewizyta_services/src/analytics/analytics_service.dart';

/// Used in tests, in local development and by self-hosters who do not want
/// analytics at all.
final class const NoopAnalyticsService() implements AnalyticsService {
  @override
  Future<void> init() async {}

  @override
  Future<void> capture(String event, {Map<String, Object?> properties = const {}}) async {}

  @override
  Future<void> screen(String name) async {}

  @override
  Future<void> identify(String userId, {Map<String, Object?> properties = const {}}) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> setEnabled({required bool enabled}) async {}
}
