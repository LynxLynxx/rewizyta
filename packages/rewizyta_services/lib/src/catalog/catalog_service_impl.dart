import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:rewizyta_services/src/catalog/catalog_service.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:uuid/uuid.dart';

final class CatalogServiceImpl(
  final TradesRepository _trades,
  final ServiceTypesRepository _serviceTypes,
  final TransactionRunner _transaction, {
  DateTime Function()? now,
  Uuid? uuid,
}) implements CatalogService {
  final DateTime Function() _now = now ?? DateTime.timestamp;
  final Uuid _uuid = uuid ?? const Uuid();

  @override
  Future<void> copyDefaults(Iterable<TradeTemplate> trades) {
    final picked = trades.toSet();
    final now = _now();
    return _transaction.run(() async {
      // Catalogue order, not pick order, so sort_order is stable.
      for (final template in TradeTemplate.values.where(picked.contains)) {
        final trade = await _copyTrade(template, now);
        for (final (sortOrder, typeTemplate) in template.serviceTypes.indexed) {
          await _copyServiceType(typeTemplate, trade.id, sortOrder, now);
        }
      }
    });
  }

  Future<Trade> _copyTrade(TradeTemplate template, DateTime now) async {
    final existing = await _trades.findByTemplate(template);
    if (existing != null && !existing.isDeleted) {
      return existing;
    }
    final trade =
        existing?.copyWith(updatedAt: now, deletedAt: const Optional.empty()) ??
        Trade(
          id: _uuid.v4(),
          template: template,
          sortOrder: template.index,
          createdAt: now,
          updatedAt: now,
        );
    await _trades.upsert(trade);
    return trade;
  }

  Future<void> _copyServiceType(
    ServiceTypeTemplate template,
    String tradeId,
    int sortOrder,
    DateTime now,
  ) async {
    final existing = await _serviceTypes.findByTemplate(template);
    if (existing == null) {
      await _serviceTypes.upsert(
        ServiceType(
          id: _uuid.v4(),
          tradeId: tradeId,
          cycleMonths: template.cycleMonths,
          template: template,
          sortOrder: sortOrder,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else if (existing.isDeleted) {
      // A restored type stays under its own trade while that one is live; a
      // purged trade (trade_id null) or a deleted one sends it back under [tradeId].
      final current = switch (existing.tradeId) {
        final id? => await _trades.find(id),
        null => null,
      };
      await _serviceTypes.upsert(
        existing.copyWith(
          tradeId: Optional(current != null && !current.isDeleted ? current.id : tradeId),
          updatedAt: now,
          deletedAt: const Optional.empty(),
        ),
      );
    }
  }
}
