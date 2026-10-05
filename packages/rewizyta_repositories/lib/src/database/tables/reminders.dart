import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';
import 'package:rewizyta_repositories/src/database/tables/appointments.dart';
import 'package:rewizyta_repositories/src/database/tables/clients.dart';
import 'package:rewizyta_repositories/src/database/tables/equipment.dart';
import 'package:rewizyta_repositories/src/database/tables/synced_columns.dart';

/// Mirrors `public.reminders`. The server writes most rows; the phone writes
/// manual ones and pulls the rest for the client's message history. The
/// server's uniqueness rule for the daily job is not repeated here.
@DataClassName('ReminderRow')
@TableIndex(name: 'reminders_client_id', columns: {#clientId})
class Reminders() extends Table with SyncedColumns {
  TextColumn get clientId => text().references(
    Clients,
    #id,
    onDelete: KeyAction.cascade,
    initiallyDeferred: true,
  )();
  TextColumn get kind => text().map(const EnumConverter(ReminderKind.values))();
  TextColumn get equipmentId => text().nullable().references(
    EquipmentTable,
    #id,
    onDelete: KeyAction.setNull,
    initiallyDeferred: true,
  )();
  TextColumn get appointmentId => text().nullable().references(
    Appointments,
    #id,
    onDelete: KeyAction.setNull,
    initiallyDeferred: true,
  )();
  TextColumn get dueOn => text().nullable().map(const DateConverter())();
  IntColumn get offsetDays => integer().nullable()();
  DateTimeColumn get sendAt => dateTime()();
  TextColumn get phone => text()();
  TextColumn get body => text()();
  TextColumn get status => text()
      .withDefault(const Constant('pending'))
      .map(const EnumConverter(ReminderStatus.values))();
  TextColumn get providerMessageId => text().nullable()();
  DateTimeColumn get sentAt => dateTime().nullable()();
  TextColumn get error => text().nullable()();
}
