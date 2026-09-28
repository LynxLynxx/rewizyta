import 'package:drift/native.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late ClientsRepositoryImpl repository;

  Client client({String id = 'c1', String name = 'Jan Kowalski', DateTime? deletedAt}) {
    final now = DateTime.utc(2026, 9, 28, 10);
    return Client(id: id, name: name, createdAt: now, updatedAt: now, deletedAt: deletedAt);
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ClientsRepositoryImpl(db);
  });

  tearDown(() => db.close());

  test('upsert writes the row and one outbox entry in the same transaction', () async {
    await repository.upsert(client());

    expect(await repository.find('c1'), client());
    final outbox = await db.select(db.outbox).get();
    expect(outbox, hasLength(1));
    expect(outbox.single.entity, SyncEntity.clients);
    expect(outbox.single.op, OutboxOp.upsert.name);
    expect(outbox.single.payload, contains('"name":"Jan Kowalski"'));
  });

  test('watchAll hides soft-deleted rows and sorts by name', () async {
    await repository.upsert(client(id: 'b', name: 'Zofia'));
    await repository.upsert(client(id: 'a', name: 'Adam'));
    await repository.upsert(client(id: 'x', name: 'Usunięty', deletedAt: DateTime.utc(2026)));

    final names = await repository.watchAll().first;
    expect(names.map((c) => c.name), ['Adam', 'Zofia']);
  });

  test('a deleted client is queued as a delete', () async {
    await repository.upsert(client(deletedAt: DateTime.utc(2026)));

    final entry = await (db.select(db.outbox)..limit(1)).getSingle();
    expect(entry.op, OutboxOp.delete.name);
  });
}
