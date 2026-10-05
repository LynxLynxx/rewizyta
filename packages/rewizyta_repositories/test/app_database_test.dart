import 'package:drift/native.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:test/test.dart';

import 'helpers/fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));

  tearDown(() => db.close());

  test('foreign keys are checked at the end of the transaction, not per row', () async {
    // A pull may apply a child before its parent.
    await db.transaction(() async {
      await EquipmentRepositoryImpl(db).upsert(equipment());
      await ServiceTypesRepositoryImpl(db).upsert(serviceType());
      await ClientsRepositoryImpl(db).upsert(client());
    });

    expect(await EquipmentRepositoryImpl(db).find('e1'), isNotNull);
  });

  group('TransactionRunnerImpl', () {
    test('commits the writes of several repositories together', () async {
      final result = await TransactionRunnerImpl(db).run(() async {
        await ClientsRepositoryImpl(db).upsert(client());
        await ServiceTypesRepositoryImpl(db).upsert(serviceType());
        await EquipmentRepositoryImpl(db).upsert(equipment());
        return 'done';
      });

      expect(result, 'done');
      expect(await EquipmentRepositoryImpl(db).find('e1'), isNotNull);
      expect(await db.select(db.outbox).get(), hasLength(3));
    });

    test('rolls every write back, outbox included, when the action throws', () async {
      await expectLater(
        TransactionRunnerImpl(db).run<void>(() async {
          await ClientsRepositoryImpl(db).upsert(client());
          await TradesRepositoryImpl(db).upsert(trade());
          throw StateError('recompute failed');
        }),
        throwsStateError,
      );

      expect(await ClientsRepositoryImpl(db).find('c1'), isNull);
      expect(await TradesRepositoryImpl(db).find('t1'), isNull);
      expect(await db.select(db.outbox).get(), isEmpty);
    });
  });

  test('a transaction that leaves a dangling reference is rolled back', () async {
    await expectLater(
      TransactionRunnerImpl(db).run(() async {
        await ClientsRepositoryImpl(db).upsert(client());
        await EquipmentRepositoryImpl(db).upsert(equipment(serviceTypeId: 'missing'));
      }),
      throwsA(isA<SqliteException>()),
    );

    expect(await ClientsRepositoryImpl(db).find('c1'), isNull);
    expect(await db.select(db.outbox).get(), isEmpty);
  });

  test('purging a client removes its rows and clears optional links to them', () async {
    await ClientsRepositoryImpl(db).upsert(client());
    await ServiceTypesRepositoryImpl(db).upsert(serviceType());
    await EquipmentRepositoryImpl(db).upsert(equipment());
    await AppointmentsRepositoryImpl(db).upsert(appointment());
    await VisitsRepositoryImpl(db).upsert(visit(appointmentId: 'a1'));
    await VisitItemsRepositoryImpl(db).upsert(visitItem());

    await (db.delete(db.appointments)..where((a) => a.id.equals('a1'))).go();
    expect((await VisitsRepositoryImpl(db).find('v1'))?.appointmentId, isNull);

    await (db.delete(db.clients)..where((c) => c.id.equals('c1'))).go();
    expect(await db.select(db.equipmentTable).get(), isEmpty);
    expect(await db.select(db.visits).get(), isEmpty);
    expect(await db.select(db.visitItems).get(), isEmpty);
  });
}
