import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/client/client_row_mapping.dart';
import 'package:rewizyta_repositories/src/client/clients_repository.dart';
import 'package:rewizyta_repositories/src/client/dto/client_dto.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';
import 'package:rewizyta_repositories/src/database/outbox_writer.dart';

final class const ClientsRepositoryImpl(final AppDatabase _db) implements ClientsRepository {
  @override
  Stream<List<Client>> watchAll() {
    final query = _db.select(_db.clients)
      ..where((c) => c.deletedAt.isNull())
      ..orderBy([(c) => OrderingTerm.asc(c.name)]);
    return query.watch().map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  @override
  Future<Client?> find(String id) async {
    final row = await (_db.select(_db.clients)..where((c) => c.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> upsert(Client client) => _db.upsertSynced(
    _db.clients,
    client.toCompanion(),
    id: client.id,
    isDeleted: client.isDeleted,
    payload: ClientDto.fromDomain(client).toJson(),
  );
}
