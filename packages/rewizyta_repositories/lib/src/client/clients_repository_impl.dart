import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/client/clients_repository.dart';
import 'package:rewizyta_repositories/src/client/dto/client_dto.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';
import 'package:rewizyta_repositories/src/database/outbox_entry.dart';

final class const ClientsRepositoryImpl(final AppDatabase _db) implements ClientsRepository {
  @override
  Stream<List<Client>> watchAll() {
    final query = _db.select(_db.clients)
      ..where((c) => c.deletedAt.isNull())
      ..orderBy([(c) => OrderingTerm.asc(c.name)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<Client?> find(String id) async {
    final row = await (_db.select(_db.clients)..where((c) => c.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> upsert(Client client) {
    return _db.transaction(() async {
      await _db.into(_db.clients).insertOnConflictUpdate(_toRow(client));
      await _db
          .into(_db.outbox)
          .insert(
            OutboxCompanion.insert(
              entity: SyncEntity.clients,
              entityId: client.id,
              op: (client.isDeleted ? OutboxOp.delete : OutboxOp.upsert).name,
              payload: jsonEncode(ClientDto.fromDomain(client).toJson()),
              createdAt: DateTime.now().toUtc(),
            ),
          );
    });
  }

  static Client _toDomain(ClientRow row) => Client(
    id: row.id,
    name: row.name,
    phone: row.phone,
    address: row.address,
    town: row.town,
    note: row.note,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  );

  static ClientsCompanion _toRow(Client client) => ClientsCompanion.insert(
    id: client.id,
    name: client.name,
    phone: Value(client.phone),
    address: Value(client.address),
    town: Value(client.town),
    note: Value(client.note),
    createdAt: client.createdAt,
    updatedAt: client.updatedAt,
    deletedAt: Value(client.deletedAt),
  );
}
