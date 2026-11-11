import 'package:flutter_test/flutter_test.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

void main() {
  test('formatDate pads the day and month', () {
    expect(formatDate(DateTime.utc(2026, 3)), '01.03.2026');
  });

  test('parseDate reads a typed day, with or without padding', () {
    expect(parseDate('14.10.2025'), DateTime.utc(2025, 10, 14));
    expect(parseDate(' 1.3.2026 '), DateTime.utc(2026, 3));
  });

  test('parseDate rejects what is not a real full date', () {
    for (final text in ['', '14.10', '14.10.25', '14-10-2025', '31.02.2026', '01.13.2026']) {
      expect(parseDate(text), isNull, reason: text);
    }
  });

  test('calendarDay keeps the local day whatever the hour', () {
    expect(calendarDay(DateTime(2026, 11, 4, 23, 59)), DateTime.utc(2026, 11, 4));
  });

  test('LastVisitError allows empty and past days, and today', () {
    final today = DateTime.utc(2026, 11, 4);
    expect(LastVisitError.of(' ', today), isNull);
    expect(LastVisitError.of('04.11.2026', today), isNull);
    expect(LastVisitError.of('14.10', today), LastVisitError.invalid);
    expect(LastVisitError.of('05.11.2026', today), LastVisitError.future);
  });
}
