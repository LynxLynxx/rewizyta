import 'package:drift/native.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:test/test.dart';

import 'helpers/fixtures.dart';

void main() {
  late AppDatabase db;
  late ClientsRepositoryImpl repository;

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
    expect(outbox.single.entity, 'clients');
    expect(outbox.single.op, OutboxOp.upsert.name);
    expect(outbox.single.payload, contains('"name":"Jan Kowalski"'));
  });

  test('round-trips every column', () async {
    final full = Client(
      id: 'c1',
      name: 'Jan Kowalski',
      phone: '+48601234567',
      addressLine: 'ul. Leśna 12',
      town: 'Nowy Targ',
      postalCode: '34-400',
      lat: 49.48,
      lng: 20.03,
      note: 'Pies na podwórku',
      contactId: 'contact-1',
      createdAt: t0,
      updatedAt: t0,
    );

    await repository.upsert(full);

    expect(await repository.find('c1'), full);
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

  test('a newer write replaces the pending outbox entry for the same row', () async {
    await repository.upsert(client(name: 'Jan'));
    await repository.upsert(client());
    await repository.upsert(client(id: 'c2', name: 'Anna'));

    final outbox = await db.select(db.outbox).get();
    expect(outbox.map((e) => e.entityId), ['c1', 'c2']);
    expect(outbox.first.payload, contains('"name":"Jan Kowalski"'));
  });

  test('local timestamps are stored as UTC', () async {
    final local = DateTime(2026, 9, 28, 12);
    await repository.upsert(Client(id: 'c1', name: 'Jan', createdAt: local, updatedAt: local));

    final found = await repository.find('c1');
    expect(found!.createdAt.isUtc, isTrue);
    expect(found.createdAt, local.toUtc());
  });
}
