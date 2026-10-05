import 'package:drift/drift.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';
import 'package:rewizyta_repositories/src/settings/app_settings_repository.dart';

final class const AppSettingsRepositoryImpl(final AppDatabase _db)
    implements AppSettingsRepository {
  @override
  Future<String?> read(AppSettingKey key) async => (await _query(key).getSingleOrNull())?.value;

  @override
  Stream<String?> watch(AppSettingKey key) =>
      _query(key).watchSingleOrNull().map((row) => row?.value).distinct();

  @override
  Future<void> write(AppSettingKey key, String? value) async {
    if (value == null) {
      await (_db.delete(_db.appSettings)..where((s) => s.key.equals(enumToSql(key)))).go();
    } else {
      await _db
          .into(_db.appSettings)
          .insertOnConflictUpdate(AppSettingsCompanion.insert(key: enumToSql(key), value: value));
    }
  }

  SimpleSelectStatement<$AppSettingsTable, AppSettingRow> _query(AppSettingKey key) =>
      _db.select(_db.appSettings)..where((s) => s.key.equals(enumToSql(key)));
}
