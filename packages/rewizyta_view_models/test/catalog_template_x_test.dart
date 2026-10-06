import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('pl'));
  final now = DateTime.utc(2026);

  group('TradeTemplateX and ServiceTypeTemplateX', () {
    test('every template has its own non-empty name', () {
      final names = [
        for (final template in TradeTemplate.values) template.localizedName(l10n),
        for (final template in ServiceTypeTemplate.values) template.localizedName(l10n),
      ];

      expect(names, everyElement(isNotEmpty));
      expect(names.toSet(), hasLength(names.length));
    });
  });

  group('TradeNameX', () {
    final trade = Trade(id: 't1', template: TradeTemplate.gas, createdAt: now, updatedAt: now);

    test('a default shows its localized name', () {
      expect(trade.localizedName(l10n), 'Serwisant gazowy');
    });

    test('a renamed default shows the user name', () {
      expect(trade.copyWith(name: const Optional('Gaz')).localizedName(l10n), 'Gaz');
    });
  });

  group('ServiceTypeNameX', () {
    final type = ServiceType(
      id: 's1',
      cycleMonths: 3,
      template: ServiceTypeTemplate.chimneySweepSolid,
      createdAt: now,
      updatedAt: now,
    );

    test('a default shows its localized name', () {
      expect(type.localizedName(l10n), 'Czyszczenie – paliwo stałe');
    });

    test('a renamed default shows the user name', () {
      final renamed = type.copyWith(name: const Optional('Kocioł węglowy'));
      expect(renamed.localizedName(l10n), 'Kocioł węglowy');
    });
  });
}
