/// Data layer. Exports the database, the repository interfaces and the DTOs.
/// Implementations are exported too because the app's DI container must
/// construct them; no other package may import them.
library;

export 'src/client/clients_repository.dart';
export 'src/client/clients_repository_impl.dart';
export 'src/client/dto/client_dto.dart';
export 'src/database/app_database.dart';
export 'src/database/outbox_entry.dart';
