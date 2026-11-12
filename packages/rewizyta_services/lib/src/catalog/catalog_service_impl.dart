import 'dart:math' as math;

import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:rewizyta_services/src/catalog/catalog_service.dart';
import 'package:rewizyta_services/src/common/clean_text.dart';
import 'package:rewizyta_services/src/due/due_date_updater.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:uuid/uuid.dart';

final class CatalogServiceImpl(
  final TradesRepository _trades,
  final ServiceTypesRepository _serviceTypes,
  EquipmentRepository equipment,
  VisitsRepository visits,
  final TransactionRunner _transaction, {
  DateTime Function()? now,
  Uuid? uuid,
}) implements CatalogService {
  final DueDateUpdater _due = DueDateUpdater(visits, equipment, _serviceTypes);
  final DateTime Function() _now = now ?? DateTime.timestamp;
  final Uuid _uuid = uuid ?? const Uuid();

  @override
  Stream<List<Trade>> watchTrades() => _trades.watchAll();

  @override
  Stream<List<ServiceType>> watchServiceTypes() => _serviceTypes.watchAll();

  @override
  Future<void> addTrade(String name) async {
    final cleanName = cleanText(name);
    if (cleanName == null) {
      throw const TradeValidationException(TradeValidationError.nameEmpty);
    }
    final trades = await _trades.watchAll().first;
    final now = _now();
    await _trades.upsert(
      Trade(
        id: _uuid.v4(),
        name: cleanName,
        sortOrder: _after(trades.map((trade) => trade.sortOrder), TradeTemplate.values.length),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> saveServiceType({
    String? id,
    required String tradeId,
    required String name,
    required int cycleMonths,
    int? defaultPriceGrosze,
    bool isArchived = false,
  }) async {
    if (cycleMonths < 1) {
      throw const ServiceTypeValidationException(ServiceTypeValidationError.cycleBelowOne);
    }
    if (cycleMonths > ServiceType.maxCycleMonths) {
      throw const ServiceTypeValidationException(ServiceTypeValidationError.cycleTooLong);
    }
    final cleanName = cleanText(name);
    if (id == null) {
      if (cleanName == null) {
        throw const ServiceTypeValidationException(ServiceTypeValidationError.nameEmpty);
      }
      final types = await _serviceTypes.watchAll().first;
      final now = _now();
      await _serviceTypes.upsert(
        ServiceType(
          id: _uuid.v4(),
          tradeId: tradeId,
          name: cleanName,
          cycleMonths: cycleMonths,
          defaultPriceGrosze: defaultPriceGrosze,
          sortOrder: _after(
            types.map((type) => type.sortOrder),
            ServiceTypeTemplate.values.length,
          ),
          isArchived: isArchived,
          createdAt: now,
          updatedAt: now,
        ),
      );
      return;
    }
    final now = _now();
    await _transaction.run(() async {
      final existing = await _serviceTypes.find(id);
      if (existing == null) {
        throw ServiceTypeNotFoundException(id);
      }
      if (cleanName == null && existing.template == null) {
        throw const ServiceTypeValidationException(ServiceTypeValidationError.nameEmpty);
      }
      // A blank name on a default stores null, so its localized name returns.
      final updated = existing.copyWith(
        name: Optional(cleanName),
        tradeId: Optional(tradeId),
        cycleMonths: cycleMonths,
        defaultPriceGrosze: Optional(defaultPriceGrosze),
        isArchived: isArchived,
      );
      if (updated == existing) {
        return;
      }
      await _serviceTypes.upsert(updated.copyWith(updatedAt: now));
      if (updated.cycleMonths != existing.cycleMonths) {
        await _due.updateServiceType(updated, now);
      }
    });
  }

  @override
  Future<void> ensureDefaults() async {
    final existing = await _serviceTypes.watchAll().first;
    if (existing.isEmpty) await copyDefaults(TradeTemplate.values);
  }

  @override
  Future<void> copyDefaults(Iterable<TradeTemplate> trades) {
    final picked = trades.toSet();
    final now = _now();
    return _transaction.run(() async {
      // Catalogue order, not pick order, so sort_order is stable.
      for (final template in TradeTemplate.values.where(picked.contains)) {
        final trade = await _copyTrade(template, now);
        for (final typeTemplate in template.serviceTypes) {
          await _copyServiceType(typeTemplate, trade.id, now);
        }
      }
    });
  }

  /// The sort order after [sortOrders] and after the first [defaults] slots,
  /// which [copyDefaults] fills by template index, so defaults restored later
  /// still come first. A template added in a later release can tie with the
  /// first custom row (then the older row wins).
  static int _after(Iterable<int> sortOrders, int defaults) =>
      sortOrders.fold(defaults - 1, math.max) + 1;

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
          // Across the catalogue, not per trade: pickers list the types of all
          // trades together, and a tie would fall to the random id.
          sortOrder: template.index,
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
