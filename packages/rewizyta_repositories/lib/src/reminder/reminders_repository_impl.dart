import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';
import 'package:rewizyta_repositories/src/database/outbox_writer.dart';
import 'package:rewizyta_repositories/src/reminder/dto/reminder_dto.dart';
import 'package:rewizyta_repositories/src/reminder/reminder_row_mapping.dart';
import 'package:rewizyta_repositories/src/reminder/reminders_repository.dart';

final class const RemindersRepositoryImpl(final AppDatabase _db) implements RemindersRepository {
  @override
  Stream<List<Reminder>> watchByClient(String clientId) {
    final query = _db.select(_db.reminders)
      ..where((r) => r.clientId.equals(clientId) & r.deletedAt.isNull())
      ..orderBy([(r) => OrderingTerm.desc(r.sendAt)]);
    return query.watch().map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  @override
  Future<Reminder?> find(String id) async {
    final row = await (_db.select(_db.reminders)..where((r) => r.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> upsert(Reminder reminder) => _db.upsertSynced(
    _db.reminders,
    reminder.toCompanion(),
    id: reminder.id,
    isDeleted: reminder.isDeleted,
    payload: ReminderDto.fromDomain(reminder).toJson(),
  );
}
