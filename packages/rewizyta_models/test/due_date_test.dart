import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:test/test.dart';

void main() {
  group('nextDue', () {
    test('adds whole months', () {
      expect(nextDue(DateTime.utc(2026, 3, 15), 3), DateTime.utc(2026, 6, 15));
    });

    test('rolls over the year', () {
      expect(nextDue(DateTime.utc(2026, 11, 10), 3), DateTime.utc(2027, 2, 10));
      expect(nextDue(DateTime.utc(2026, 5, 2), 12), DateTime.utc(2027, 5, 2));
    });

    test('clamps to the end of a shorter month', () {
      expect(nextDue(DateTime.utc(2026, 1, 31), 1), DateTime.utc(2026, 2, 28));
      expect(nextDue(DateTime.utc(2028, 1, 31), 1), DateTime.utc(2028, 2, 29));
      expect(nextDue(DateTime.utc(2026, 3, 31), 1), DateTime.utc(2026, 4, 30));
    });
  });
}
