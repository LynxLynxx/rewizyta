import 'package:drift/drift.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';
import 'package:rewizyta_repositories/src/database/tables/appointments.dart';
import 'package:rewizyta_repositories/src/database/tables/clients.dart';
import 'package:rewizyta_repositories/src/database/tables/synced_columns.dart';

/// Mirrors `public.visits`. Deleting the appointment a visit fulfilled keeps
/// the visit.
@DataClassName('VisitRow')
@TableIndex(name: 'visits_client_id_done_at', columns: {#clientId, #doneAt})
class Visits() extends Table with SyncedColumns {
  TextColumn get clientId => text().references(
    Clients,
    #id,
    onDelete: KeyAction.cascade,
    initiallyDeferred: true,
  )();
  TextColumn get doneAt => text().map(const DateConverter())();
  IntColumn get priceGrosze => integer().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get appointmentId => text().nullable().references(
    Appointments,
    #id,
    onDelete: KeyAction.setNull,
    initiallyDeferred: true,
  )();
}
