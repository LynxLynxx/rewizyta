import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('pl'));
  final now = DateTime.utc(2026);

  ServiceType type(String id, String tradeId) => ServiceType(
    id: id,
    tradeId: tradeId,
    name: id,
    cycleMonths: 12,
    createdAt: now,
    updatedAt: now,
  );

  group('CatalogTradeViewModel', () {
    final chimney = Trade(
      id: 't1',
      template: TradeTemplate.chimney,
      createdAt: now,
      updatedAt: now,
    );

    test('fromDomain keeps the types of its trade, in their order', () {
      final trade = CatalogTradeViewModel.fromDomain(chimney, [
        type('b', 't1'),
        type('x', 't2'),
        type('a', 't1'),
      ]);

      expect(trade.id, 't1');
      expect(trade.serviceTypes.map((s) => s.id), ['b', 'a']);
    });

    test('a default shows its localized name until it is renamed', () {
      expect(CatalogTradeViewModel.fromDomain(chimney, const []).localizedName(l10n), 'Kominiarz');
      expect(
        const CatalogTradeViewModel(id: 't2', name: 'Wentylacja').localizedName(l10n),
        'Wentylacja',
      );
    });
  });

  group('ServiceTypeViewModel.details', () {
    test('a cycle alone', () {
      const type = ServiceTypeViewModel(id: 's1', name: 'Komin', cycleMonths: 12);

      expect(type.details(l10n), 'co 12 mies.');
    });

    test('the cycle, the default price and the archive', () {
      final type = ServiceTypeViewModel.fromDomain(
        ServiceType(
          id: 's1',
          template: ServiceTypeTemplate.chimneySweepSolid,
          cycleMonths: 3,
          defaultPriceGrosze: 18050,
          isArchived: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(type.details(l10n), 'co 3 mies. · 180,50 zł · w archiwum');
    });
  });
}
