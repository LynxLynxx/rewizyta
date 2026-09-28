/// Domain layer. Cubits inject these services; nothing above this package may
/// touch a repository directly.
///
/// Adapters for third-party SDKs (analytics, reporting, push) are declared here
/// as interfaces with no-op implementations. Vendor implementations live in
/// the app (apps/mobile/lib/app/integrations/) because they need platform
/// plugins, and are chosen in the DI container from AppConfig.
library;

export 'src/analytics/analytics_service.dart';
export 'src/analytics/noop_analytics_service.dart';
export 'src/client/clients_service.dart';
export 'src/client/clients_service_impl.dart';
export 'src/push/noop_push_notifications_service.dart';
export 'src/push/push_notifications_service.dart';
export 'src/reporting/noop_reporting_service.dart';
export 'src/reporting/reporting_service.dart';
