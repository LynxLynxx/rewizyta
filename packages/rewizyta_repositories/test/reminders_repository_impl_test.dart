import 'package:drift/native.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:test/test.dart';

import 'helpers/fixtures.dart';

void main() {
  late AppDatabase db;
  late RemindersRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = RemindersRepositoryImpl(db);
    await ClientsRepositoryImpl(db).upsert(client());
    await ServiceTypesRepositoryImpl(db).upsert(serviceType());
    await EquipmentRepositoryImpl(db).upsert(equipment());
  });

  tearDown(() => db.close());

  test('upsert round-trips a due reminder and queues it', () async {
    final due = Reminder(
      id: 'r1',
      clientId: 'c1',
      kind: ReminderKind.due,
      equipmentId: 'e1',
      dueOn: DateTime.utc(2026, 11),
      offsetDays: 30,
      sendAt: DateTime.utc(2026, 10, 2, 6),
      phone: '+48601234567',
      body: 'Dzień dobry, zbliża się termin przeglądu.',
      status: ReminderStatus.delivered,
      providerMessageId: 'msg-1',
      sentAt: DateTime.utc(2026, 10, 2, 6, 1),
      createdAt: t0,
      updatedAt: t0,
    );

    await repository.upsert(due);

    expect(await repository.find('r1'), due);
    final entry = await (db.select(
      db.outbox,
    )..where((o) => o.entity.equals('reminders'))).getSingle();
    expect(entry.payload, allOf(contains('"kind":"due"'), contains('"due_on":"2026-11-01"')));
  });

  test("watchByClient lists the client's live reminders, latest first", () async {
    await repository.upsert(reminder(sendAt: DateTime.utc(2026, 9)));
    await repository.upsert(reminder(id: 'r2', sendAt: DateTime.utc(2026, 10)));
    await repository.upsert(reminder(id: 'gone', deletedAt: t0));

    final list = await repository.watchByClient('c1').first;
    expect(list.map((r) => r.id), ['r2', 'r1']);
  });
}
