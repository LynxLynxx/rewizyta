import 'package:drift/native.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:test/test.dart';

import 'helpers/fixtures.dart';

void main() {
  late AppDatabase db;
  late TradesRepositoryImpl trades;
  late ServiceTypesRepositoryImpl serviceTypes;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    trades = TradesRepositoryImpl(db);
    serviceTypes = ServiceTypesRepositoryImpl(db);
  });

  tearDown(() => db.close());

  group('TradesRepositoryImpl', () {
    test('upsert round-trips and queues the row', () async {
      await trades.upsert(trade(template: TradeTemplate.chimney));

      expect(await trades.find('t1'), trade(template: TradeTemplate.chimney));
      final entry = await db.select(db.outbox).getSingle();
      expect(entry.entity, 'trades');
      expect(entry.payload, contains('"template_key":"chimney"'));
    });

    test('watchAll hides deleted trades and follows sort order, then creation', () async {
      // A default has no name, so a name sort would put it first.
      final later = t0.add(const Duration(hours: 1));
      await trades.upsert(
        trade(id: 'a', name: null, template: TradeTemplate.gas, sortOrder: 1, createdAt: later),
      );
      await trades.upsert(trade(id: 'b', name: 'Agregaty', sortOrder: 1));
      await trades.upsert(trade(id: 'z', name: 'Zduński'));
      await trades.upsert(trade(id: 'x', name: 'Usunięty', deletedAt: t0));

      final list = await trades.watchAll().first;
      expect(list.map((t) => t.id), ['z', 'b', 'a']);
    });

    test('findByTemplate finds a soft-deleted default too', () async {
      await trades.upsert(trade(template: TradeTemplate.chimney, deletedAt: t0));

      expect((await trades.findByTemplate(TradeTemplate.chimney))?.id, 't1');
      expect(await trades.findByTemplate(TradeTemplate.gas), isNull);
    });

    test('a default can be copied only once', () async {
      await trades.upsert(trade(template: TradeTemplate.chimney));

      expect(
        () => trades.upsert(trade(id: 't2', template: TradeTemplate.chimney)),
        throwsA(isA<SqliteException>()),
      );
    });

    test('a trade needs a name or a template', () async {
      await trades.upsert(trade(name: null, template: TradeTemplate.gas));

      expect((await trades.find('t1'))?.name, isNull);
      expect(
        () => db
            .into(db.trades)
            .insert(TradesCompanion.insert(id: 't2', createdAt: t0, updatedAt: t0)),
        throwsA(isA<SqliteException>()),
      );
    });

    test("the user's own trades have no template key and never collide", () async {
      await trades.upsert(trade());
      await trades.upsert(trade(id: 't2'));

      expect(await trades.watchAll().first, hasLength(2));
    });
  });

  group('ServiceTypesRepositoryImpl', () {
    test('upsert round-trips and queues the row', () async {
      await trades.upsert(trade());
      final type = serviceType(
        tradeId: 't1',
        template: ServiceTypeTemplate.chimneyInspection,
        defaultPriceGrosze: 25000,
      );

      await serviceTypes.upsert(type);

      expect(await serviceTypes.find('s1'), type);
      final entries = await db.select(db.outbox).get();
      expect(entries.last.entity, 'service_types');
      expect(
        entries.last.payload,
        allOf(contains('"cycle_months":12'), contains('"default_price_grosze":25000')),
      );
    });

    test('watchAll hides deleted types', () async {
      await serviceTypes.upsert(serviceType());
      await serviceTypes.upsert(serviceType(id: 's2', deletedAt: t0));

      expect((await serviceTypes.watchAll().first).map((s) => s.id), ['s1']);
    });

    test('findByTemplate finds a soft-deleted default too', () async {
      await serviceTypes.upsert(
        serviceType(template: ServiceTypeTemplate.gasInstallationCheck, deletedAt: t0),
      );

      expect(
        (await serviceTypes.findByTemplate(ServiceTypeTemplate.gasInstallationCheck))?.id,
        's1',
      );
    });

    test('a type needs a name or a template', () {
      expect(
        () => db
            .into(db.serviceTypes)
            .insert(
              ServiceTypesCompanion.insert(id: 's1', cycleMonths: 12, createdAt: t0, updatedAt: t0),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('a cycle must be positive', () {
      expect(
        () => serviceTypes.upsert(serviceType(cycleMonths: 0)),
        throwsA(isA<SqliteException>()),
      );
    });

    test('a type cannot point at a trade that does not exist', () {
      expect(
        () => serviceTypes.upsert(serviceType(tradeId: 'missing')),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}
