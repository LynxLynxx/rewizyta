import 'package:drift/native.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:test/test.dart';

import 'helpers/fixtures.dart';

void main() {
  late AppDatabase db;
  late AppointmentsRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = AppointmentsRepositoryImpl(db);
    await ClientsRepositoryImpl(db).upsert(client());
    await ClientsRepositoryImpl(db).upsert(client(id: 'c2'));
  });

  tearDown(() => db.close());

  test('upsert round-trips and queues the status in snake_case', () async {
    final noShow = appointment(status: AppointmentStatus.noShow);

    await repository.upsert(noShow);

    expect(await repository.find('a1'), noShow);
    final entry = await (db.select(
      db.outbox,
    )..where((o) => o.entity.equals('appointments'))).getSingle();
    expect(entry.payload, contains('"status":"no_show"'));
    final raw = await db
        .customSelect("select status from appointments where id = 'a1'")
        .getSingle();
    expect(raw.read<String>('status'), 'no_show');
  });

  test('upsert round-trips the route position and the fixed time', () async {
    final pinned = appointment(isTimeFixed: true, routePosition: 2);

    await repository.upsert(pinned);

    expect(await repository.find('a1'), pinned);
    final entry = await (db.select(
      db.outbox,
    )..where((o) => o.entity.equals('appointments'))).getSingle();
    expect(entry.payload, allOf(contains('"route_position":2'), contains('"is_time_fixed":true')));
  });

  group('stops between', () {
    final day = DateTime.utc(2026, 10, 5);
    final to = day.add(const Duration(days: 1));

    /// Two live stops in the day ("early" at c2, "late" at c1), plus a deleted
    /// one, one on the next day and one at the soft-deleted client c3.
    Future<void> seedDay() async {
      await ClientsRepositoryImpl(db).upsert(client(id: 'c3', deletedAt: t0));
      await repository.upsert(
        appointment(id: 'late', startsAt: day.add(const Duration(hours: 14))),
      );
      await repository.upsert(
        appointment(id: 'early', clientId: 'c2', startsAt: day.add(const Duration(hours: 8))),
      );
      await repository.upsert(
        appointment(id: 'gone', startsAt: day.add(const Duration(hours: 9)), deletedAt: t0),
      );
      await repository.upsert(appointment(id: 'next', startsAt: to));
      await repository.upsert(
        appointment(id: 'orphan', clientId: 'c3', startsAt: day.add(const Duration(hours: 10))),
      );
    }

    List<(String, String)> ids(List<DayStop> stops) => [
      for (final stop in stops) (stop.appointment.id, stop.client.id),
    ];

    test('watchStopsBetween returns live appointments in [from, to) with their client', () async {
      await seedDay();

      final stops = await repository.watchStopsBetween(day, to).first;

      expect(ids(stops), [('early', 'c2'), ('late', 'c1')]);
      expect(stops.first.client, client(id: 'c2'));
    });

    test("findStopsBetween does the same, and a restored client's stops come back", () async {
      await seedDay();
      expect(ids(await repository.findStopsBetween(day, to)), [('early', 'c2'), ('late', 'c1')]);

      await ClientsRepositoryImpl(db).upsert(client(id: 'c3'));

      expect(ids(await repository.findStopsBetween(day, to)), [
        ('early', 'c2'),
        ('orphan', 'c3'),
        ('late', 'c1'),
      ]);
    });

    test("watchStopsBetween re-emits when the client's coordinates change", () async {
      await repository.upsert(appointment(startsAt: day.add(const Duration(hours: 8))));
      final stops = repository.watchStopsBetween(day, to);
      final expectation = expectLater(
        stops.map((list) => list.single.location),
        emitsInOrder([null, (lat: 50.06, lng: 19.94)]),
      );

      await stops.first;
      await ClientsRepositoryImpl(
        db,
      ).upsert(client().copyWith(lat: const Optional(50.06), lng: const Optional(19.94)));
      await expectation;
    });
  });

  test('watchBetween returns live appointments in [from, to), earliest first', () async {
    final day = DateTime.utc(2026, 10, 5);
    await repository.upsert(appointment(id: 'late', startsAt: day.add(const Duration(hours: 14))));
    await repository.upsert(appointment(id: 'early', startsAt: day.add(const Duration(hours: 8))));
    await repository.upsert(appointment(id: 'midnight', startsAt: day));
    await repository.upsert(appointment(id: 'next', startsAt: day.add(const Duration(days: 1))));
    await repository.upsert(
      appointment(id: 'before', startsAt: day.subtract(const Duration(minutes: 1))),
    );
    await repository.upsert(
      appointment(id: 'gone', startsAt: day.add(const Duration(hours: 9)), deletedAt: t0),
    );

    final list = await repository.watchBetween(day, day.add(const Duration(days: 1))).first;
    expect(list.map((a) => a.id), ['midnight', 'early', 'late']);
  });

  test('watchBetween compares instants, whatever zone the bounds are in', () async {
    final start = DateTime.utc(2026, 10, 5, 8);
    await repository.upsert(appointment(startsAt: start));

    final from = start.toLocal();
    final list = await repository.watchBetween(from, from.add(const Duration(hours: 1))).first;
    expect(list.map((a) => a.id), ['a1']);
  });

  test("watchByClient lists the client's live appointments, latest first", () async {
    await repository.upsert(appointment(startsAt: DateTime.utc(2026, 10)));
    await repository.upsert(appointment(id: 'a2', startsAt: DateTime.utc(2026, 11)));
    await repository.upsert(appointment(id: 'other', clientId: 'c2'));

    final list = await repository.watchByClient('c1').first;
    expect(list.map((a) => a.id), ['a2', 'a1']);
  });
}
