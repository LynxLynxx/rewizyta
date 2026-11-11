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
}
