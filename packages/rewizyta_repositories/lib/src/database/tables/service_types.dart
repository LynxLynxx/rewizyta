import 'package:drift/drift.dart';
import 'package:rewizyta_repositories/src/database/tables/synced_columns.dart';
import 'package:rewizyta_repositories/src/database/tables/trades.dart';

/// Mirrors `public.service_types`. Deleting a trade leaves its types loose
/// (`trade_id` null) rather than deleting them.
@DataClassName('ServiceTypeRow')
@TableIndex(name: 'service_types_template_key', columns: {#templateKey}, unique: true)
@TableIndex(name: 'service_types_trade_id', columns: {#tradeId})
class ServiceTypes() extends Table with SyncedColumns {
  TextColumn get tradeId => text().nullable().references(
    Trades,
    #id,
    onDelete: KeyAction.setNull,
    initiallyDeferred: true,
  )();
  TextColumn get name => text()();
  IntColumn get cycleMonths => integer()();
  IntColumn get defaultPriceGrosze => integer().nullable()();
  TextColumn get templateKey => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => ['CHECK (cycle_months > 0)'];
}
