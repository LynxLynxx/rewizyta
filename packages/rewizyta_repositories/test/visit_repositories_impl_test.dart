import 'package:drift/native.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:test/test.dart';

import 'helpers/fixtures.dart';

void main() {
  late AppDatabase db;
  late VisitsRepositoryImpl visits;
  late VisitItemsRepositoryImpl items;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    visits = VisitsRepositoryImpl(db);
    items = VisitItemsRepositoryImpl(db);
    await ClientsRepositoryImpl(db).upsert(client());
    await ServiceTypesRepositoryImpl(db).upsert(serviceType());
    await EquipmentRepositoryImpl(db).upsert(equipment());
    await EquipmentRepositoryImpl(db).upsert(equipment(id: 'e2'));
  });

  tearDown(() => db.close());

  group('VisitsRepositoryImpl', () {
    test('upsert round-trips and queues the visit with its day', () async {
      final done = visit(doneAt: DateTime.utc(2026, 9), priceGrosze: 18050);

      await visits.upsert(done);

      expect(await visits.find('v1'), done);
      final entry = await (db.select(
        db.outbox,
      )..where((o) => o.entity.equals('visits'))).getSingle();
      expect(
        entry.payload,
        allOf(contains('"done_at":"2026-09-01"'), contains('"price_grosze":18050')),
      );
    });

    test("watchByClient lists the client's live visits, newest first", () async {
      await visits.upsert(visit(id: 'old', doneAt: DateTime.utc(2025, 9)));
      await visits.upsert(visit(id: 'new', doneAt: DateTime.utc(2026, 9)));
      await visits.upsert(visit(id: 'gone', doneAt: DateTime.utc(2026, 9, 2), deletedAt: t0));

      final list = await visits.watchByClient('c1').first;
      expect(list.map((v) => v.id), ['new', 'old']);
    });

    group('lastDoneAt', () {
      test('is null for equipment never serviced', () async {
        expect(await visits.lastDoneAt('e1'), isNull);
      });

      test('is the latest day among visits that serviced the equipment', () async {
        await visits.upsert(visit(doneAt: DateTime.utc(2025, 3, 10)));
        await visits.upsert(visit(id: 'v2', doneAt: DateTime.utc(2026, 3, 10)));
        await visits.upsert(visit(id: 'v3', doneAt: DateTime.utc(2026, 6)));
        await items.upsert(visitItem());
        await items.upsert(visitItem(id: 'i2', visitId: 'v2'));
        // v3 serviced only the other item.
        await items.upsert(visitItem(id: 'i3', visitId: 'v3', equipmentId: 'e2'));

        expect(await visits.lastDoneAt('e1'), DateTime.utc(2026, 3, 10));
      });

      test('ignores deleted visits and unticked items', () async {
        await visits.upsert(visit(doneAt: DateTime.utc(2025, 3, 10)));
        await visits.upsert(visit(id: 'v2', doneAt: DateTime.utc(2026, 3, 10), deletedAt: t0));
        await visits.upsert(visit(id: 'v3', doneAt: DateTime.utc(2026, 6)));
        await items.upsert(visitItem());
        await items.upsert(visitItem(id: 'i2', visitId: 'v2'));
        await items.upsert(visitItem(id: 'i3', visitId: 'v3', deletedAt: t0));

        expect(await visits.lastDoneAt('e1'), DateTime.utc(2025, 3, 10));
      });
    });
  });

  group('VisitItemsRepositoryImpl', () {
    setUp(() => visits.upsert(visit()));

    test('findByVisit includes unticked items, so ticking again restores the row', () async {
      await items.upsert(visitItem());
      await items.upsert(visitItem(id: 'i2', equipmentId: 'e2', deletedAt: t0));

      final found = await items.findByVisit('v1');
      expect(found.map((i) => i.id), ['i1', 'i2']);

      final restored = found.last.copyWith(deletedAt: const Optional.empty());
      await items.upsert(restored);
      expect((await items.findByVisit('v1')).last.isDeleted, isFalse);
    });

    test('a visit holds one row per equipment', () async {
      await items.upsert(visitItem());

      expect(() => items.upsert(visitItem(id: 'i2')), throwsA(isA<SqliteException>()));
    });

    test('upsert queues the item', () async {
      await items.upsert(visitItem());

      final entry = await (db.select(
        db.outbox,
      )..where((o) => o.entity.equals('visit_items'))).getSingle();
      expect(entry.payload, contains('"equipment_id":"e1"'));
    });
  });
}
