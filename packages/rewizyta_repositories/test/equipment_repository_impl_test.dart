import 'package:drift/native.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:test/test.dart';

import 'helpers/fixtures.dart';

void main() {
  late AppDatabase db;
  late EquipmentRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = EquipmentRepositoryImpl(db);
    await ClientsRepositoryImpl(db).upsert(client());
    await ClientsRepositoryImpl(db).upsert(client(id: 'c2'));
    await ServiceTypesRepositoryImpl(db).upsert(serviceType());
    await ServiceTypesRepositoryImpl(db).upsert(serviceType(id: 's2', cycleMonths: 3));
  });

  tearDown(() => db.close());

  test('upsert round-trips the due-date cache as calendar days', () async {
    final item = equipment().withDue(
      lastVisitAt: DateTime.utc(2026, 1, 31),
      nextDueAt: DateTime.utc(2027, 1, 31),
      updatedAt: t0,
    );

    await repository.upsert(item);

    expect(await repository.find('e1'), item);
    final entry = await (db.select(
      db.outbox,
    )..where((o) => o.entity.equals('equipment'))).getSingle();
    expect(entry.payload, contains('"next_due_at":"2027-01-31"'));
    final raw = await db
        .customSelect("select next_due_at from equipment where id = 'e1'")
        .getSingle();
    expect(raw.read<String>('next_due_at'), '2027-01-31');
  });

  test("watchByClient lists the client's live equipment in the order it was added", () async {
    await repository.upsert(equipment(id: 'e2', createdAt: t0.add(const Duration(minutes: 1))));
    await repository.upsert(equipment());
    await repository.upsert(equipment(id: 'gone', deletedAt: t0));
    await repository.upsert(equipment(id: 'other', clientId: 'c2'));

    final list = await repository.watchByClient('c1').first;
    expect(list.map((e) => e.id), ['e1', 'e2']);
  });

  test('findByServiceType returns the live equipment of that type', () async {
    await repository.upsert(equipment());
    await repository.upsert(equipment(id: 'e2', serviceTypeId: 's2'));
    await repository.upsert(equipment(id: 'gone', deletedAt: t0));

    final list = await repository.findByServiceType('s1');
    expect(list.map((e) => e.id), ['e1']);
  });

  test('count must be positive', () {
    expect(
      () => repository.upsert(
        Equipment(
          id: 'e1',
          clientId: 'c1',
          serviceTypeId: 's1',
          count: 0,
          createdAt: t0,
          updatedAt: t0,
        ),
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('equipment cannot point at a client that does not exist', () {
    expect(
      () => repository.upsert(equipment(clientId: 'missing')),
      throwsA(isA<SqliteException>()),
    );
  });
}
