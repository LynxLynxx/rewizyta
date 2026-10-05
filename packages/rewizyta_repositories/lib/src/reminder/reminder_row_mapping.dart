import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';

/// `reminders` row ↔ [Reminder], shared by every query that reads or
/// writes the table: its repository, joins in other repositories, the sync.
/// Timestamps are written as UTC, so comparing the stored text compares
/// instants.
extension ReminderRowMapping on ReminderRow {
  Reminder toDomain() => Reminder(
    id: id,
    clientId: clientId,
    kind: kind,
    equipmentId: equipmentId,
    appointmentId: appointmentId,
    dueOn: dueOn,
    offsetDays: offsetDays,
    sendAt: sendAt,
    phone: phone,
    body: body,
    status: status,
    providerMessageId: providerMessageId,
    sentAt: sentAt,
    error: error,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

extension ReminderCompanionMapping on Reminder {
  RemindersCompanion toCompanion() => RemindersCompanion.insert(
    id: id,
    clientId: clientId,
    kind: kind,
    equipmentId: Value(equipmentId),
    appointmentId: Value(appointmentId),
    dueOn: Value(dueOn),
    offsetDays: Value(offsetDays),
    sendAt: sendAt.toUtc(),
    phone: phone,
    body: body,
    status: Value(status),
    providerMessageId: Value(providerMessageId),
    sentAt: Value(sentAt?.toUtc()),
    error: Value(error),
    createdAt: createdAt.toUtc(),
    updatedAt: updatedAt.toUtc(),
    deletedAt: Value(deletedAt?.toUtc()),
  );
}
