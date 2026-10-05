import 'package:drift/native.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:test/test.dart';

import 'helpers/fixtures.dart';

void main() {
  late AppDatabase db;
  late DevicesRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DevicesRepositoryImpl(db);
  });

  tearDown(() => db.close());

  test('upsert round-trips and queues the device', () async {
    await repository.upsert(device());

    expect(await repository.find('d1'), device());
    final entry = await db.select(db.outbox).getSingle();
    expect(entry.entity, 'devices');
    expect(
      entry.payload,
      allOf(contains('"platform":"android"'), contains('"push_provider":"fcm"')),
    );
  });
}
