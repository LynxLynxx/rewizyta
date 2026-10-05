import 'package:rewizyta_repositories/src/database/app_database.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';
import 'package:rewizyta_repositories/src/sync/sync_state_repository.dart';

final class const SyncStateRepositoryImpl(final AppDatabase _db) implements SyncStateRepository {
  @override
  Future<String?> read(SyncStateKey key) async {
    final query = _db.select(_db.syncState)..where((s) => s.key.equals(enumToSql(key)));
    return (await query.getSingleOrNull())?.value;
  }

  @override
  Future<void> write(SyncStateKey key, String? value) async {
    if (value == null) {
      await (_db.delete(_db.syncState)..where((s) => s.key.equals(enumToSql(key)))).go();
    } else {
      await _db
          .into(_db.syncState)
          .insertOnConflictUpdate(SyncStateCompanion.insert(key: enumToSql(key), value: value));
    }
  }
}
