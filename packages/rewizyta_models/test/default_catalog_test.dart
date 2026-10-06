import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:test/test.dart';

void main() {
  group('TradeTemplate', () {
    test('every service type belongs to exactly one trade and has a positive cycle', () {
      final owned = [for (final trade in TradeTemplate.values) ...trade.serviceTypes];
      expect(owned, unorderedEquals(ServiceTypeTemplate.values));
      expect(owned.map((type) => type.cycleMonths), everyElement(greaterThan(0)));
    });
  });
}
