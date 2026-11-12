import 'package:flutter_test/flutter_test.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

void main() {
  test('reads złoty the ways people type them, as grosze', () {
    expect(parseMoney('180'), 18000);
    expect(parseMoney(' 180,5 '), 18050);
    expect(parseMoney('180.05'), 18005);
    expect(parseMoney('1 200 zł'), 120000);
    expect(parseMoney('0'), 0);
  });

  test('rejects what is not an amount', () {
    for (final text in ['', 'abc', '-5', '1,234', '12,', ',5']) {
      expect(parseMoney(text), isNull, reason: text);
    }
  });

  test('formats grosze as the amount people write', () {
    expect(formatMoney(18000), '180');
    expect(formatMoney(18050), '180,50');
    expect(formatMoney(18005), '180,05');
    expect(formatMoney(0), '0');
    for (final grosze in [18000, 18050, 18005, 120000]) {
      expect(parseMoney(formatMoney(grosze)), grosze);
    }
  });
}
