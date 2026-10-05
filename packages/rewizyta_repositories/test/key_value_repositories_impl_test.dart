import 'package:drift/native.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));

  tearDown(() => db.close());

  group('SyncStateRepositoryImpl', () {
    test('writes, overwrites and removes a key under its snake_case name', () async {
      final repository = SyncStateRepositoryImpl(db);

      await repository.write(SyncStateKey.lastPulledAt, '2026-09-28T10:00:00.000Z');
      await repository.write(SyncStateKey.lastPulledAt, '2026-09-29T10:00:00.000Z');
      expect(await repository.read(SyncStateKey.lastPulledAt), '2026-09-29T10:00:00.000Z');
      expect((await db.select(db.syncState).getSingle()).key, 'last_pulled_at');

      await repository.write(SyncStateKey.lastPulledAt, null);
      expect(await repository.read(SyncStateKey.lastPulledAt), isNull);
    });

    test('never touches the outbox', () async {
      await SyncStateRepositoryImpl(db).write(SyncStateKey.deviceId, 'd1');

      expect(await db.select(db.outbox).get(), isEmpty);
    });
  });

  group('AppSettingsRepositoryImpl', () {
    test('watch emits the current value and every change', () async {
      final repository = AppSettingsRepositoryImpl(db);
      final values = <String?>[];
      final subscription = repository.watch(AppSettingKey.themeMode).listen(values.add);

      await pumpEventQueue();
      await repository.write(AppSettingKey.themeMode, 'dark');
      await pumpEventQueue();
      await repository.write(AppSettingKey.onboardingDone, 'true');
      await pumpEventQueue();
      await repository.write(AppSettingKey.themeMode, null);
      await pumpEventQueue();
      await subscription.cancel();

      expect(values, [null, 'dark', null]);
      expect(await repository.read(AppSettingKey.onboardingDone), 'true');
    });
  });
}
