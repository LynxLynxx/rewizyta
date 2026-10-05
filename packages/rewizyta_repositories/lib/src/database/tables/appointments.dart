import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';
import 'package:rewizyta_repositories/src/database/tables/clients.dart';
import 'package:rewizyta_repositories/src/database/tables/synced_columns.dart';

/// Mirrors `public.appointments`. Indexed by start for the day and week views.
@DataClassName('AppointmentRow')
@TableIndex(name: 'appointments_starts_at', columns: {#startsAt})
@TableIndex(name: 'appointments_client_id', columns: {#clientId})
class Appointments() extends Table with SyncedColumns {
  TextColumn get clientId => text().references(
    Clients,
    #id,
    onDelete: KeyAction.cascade,
    initiallyDeferred: true,
  )();
  DateTimeColumn get startsAt => dateTime()();
  IntColumn get durationMinutes => integer().withDefault(const Constant(60))();
  TextColumn get status => text()
      .withDefault(const Constant('planned'))
      .map(const EnumConverter(AppointmentStatus.values))();
  BoolColumn get isTimeFixed => boolean().withDefault(const Constant(false))();
  IntColumn get routePosition => integer().nullable()();
  TextColumn get note => text().nullable()();

  @override
  List<String> get customConstraints => ['CHECK (duration_minutes > 0)'];
}
