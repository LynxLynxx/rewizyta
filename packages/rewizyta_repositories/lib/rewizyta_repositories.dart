/// Data layer. Exports the database, the repository interfaces and the DTOs.
/// Implementations are exported too because the app's DI container must
/// construct them; no other package may import them.
library;

export 'src/appointment/appointments_repository.dart';
export 'src/appointment/appointments_repository_impl.dart';
export 'src/appointment/dto/appointment_dto.dart';
export 'src/catalog/dto/service_type_dto.dart';
export 'src/catalog/dto/trade_dto.dart';
export 'src/catalog/service_types_repository.dart';
export 'src/catalog/service_types_repository_impl.dart';
export 'src/catalog/trades_repository.dart';
export 'src/catalog/trades_repository_impl.dart';
export 'src/client/clients_repository.dart';
export 'src/client/clients_repository_impl.dart';
export 'src/client/dto/client_dto.dart';
export 'src/database/app_database.dart';
export 'src/database/outbox_writer.dart' show OutboxOp;
export 'src/database/transaction_runner.dart';
export 'src/database/transaction_runner_impl.dart';
export 'src/device/devices_repository.dart';
export 'src/device/devices_repository_impl.dart';
export 'src/device/dto/device_dto.dart';
export 'src/equipment/dto/equipment_dto.dart';
export 'src/equipment/equipment_repository.dart';
export 'src/equipment/equipment_repository_impl.dart';
export 'src/reminder/dto/reminder_dto.dart';
export 'src/reminder/reminders_repository.dart';
export 'src/reminder/reminders_repository_impl.dart';
export 'src/settings/app_settings_repository.dart';
export 'src/settings/app_settings_repository_impl.dart';
export 'src/sync/sync_state_repository.dart';
export 'src/sync/sync_state_repository_impl.dart';
export 'src/visit/dto/visit_dto.dart';
export 'src/visit/dto/visit_item_dto.dart';
export 'src/visit/visit_items_repository.dart';
export 'src/visit/visit_items_repository_impl.dart';
export 'src/visit/visits_repository.dart';
export 'src/visit/visits_repository_impl.dart';
