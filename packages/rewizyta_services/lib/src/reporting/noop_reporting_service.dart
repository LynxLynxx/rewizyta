import 'package:rewizyta_services/src/reporting/reporting_service.dart';

final class const NoopReportingService() implements ReportingService {
  @override
  Future<void> init() async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {}

  @override
  void log(String message) {}

  @override
  void setUserIdentifier(String? id) {}

  @override
  void setCustomKey(String key, Object value) {}

  @override
  Future<void> setEnabled({required bool enabled}) async {}
}
