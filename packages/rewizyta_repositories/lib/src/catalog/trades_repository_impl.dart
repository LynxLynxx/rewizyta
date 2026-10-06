import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/catalog/dto/trade_dto.dart';
import 'package:rewizyta_repositories/src/catalog/trade_row_mapping.dart';
import 'package:rewizyta_repositories/src/catalog/trades_repository.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';
import 'package:rewizyta_repositories/src/database/outbox_writer.dart';

final class const TradesRepositoryImpl(final AppDatabase _db) implements TradesRepository {
  @override
  Stream<List<Trade>> watchAll() {
    final query = _db.select(_db.trades)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.createdAt),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.watch().map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  @override
  Future<Trade?> find(String id) async {
    final row = await (_db.select(_db.trades)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<Trade?> findByTemplate(TradeTemplate template) async {
    final query = _db.select(_db.trades)..where((t) => t.templateKey.equalsValue(template));
    final row = await query.getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> upsert(Trade trade) => _db.upsertSynced(
    _db.trades,
    trade.toCompanion(),
    id: trade.id,
    isDeleted: trade.isDeleted,
    payload: TradeDto.fromDomain(trade).toJson(),
  );
}
