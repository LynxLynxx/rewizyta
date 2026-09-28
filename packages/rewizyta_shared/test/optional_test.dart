import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:test/test.dart';

void main() {
  group('Optional.dataOr', () {
    test('omitted keeps the fallback', () {
      const Optional<int>? omitted = null;
      expect(omitted.dataOr(3), 3);
    });

    test('a value replaces the fallback', () {
      expect(const Optional(5).dataOr(3), 5);
    });

    test('empty clears to null', () {
      expect(const Optional<int>.empty().dataOr(3), isNull);
    });
  });
}
