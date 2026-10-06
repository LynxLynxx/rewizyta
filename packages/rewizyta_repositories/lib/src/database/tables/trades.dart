import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';
import 'package:rewizyta_repositories/src/database/tables/synced_columns.dart';

/// Mirrors `public.trades`. A default trade is copied at most once: its
/// `template_key` is unique (NULLs, the user's own trades, do not collide).
/// `name` is null while a default keeps its localized name.
@DataClassName('TradeRow')
@TableIndex(name: 'trades_template_key', columns: {#templateKey}, unique: true)
class Trades() extends Table with SyncedColumns {
  TextColumn get name => text().nullable()();
  TextColumn get templateKey => text().nullable().map(const EnumConverter(TradeTemplate.values))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => ['CHECK (name IS NOT NULL OR template_key IS NOT NULL)'];
}
