import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('pl'));
  });

  test('formats the local time and day with leading zeros', () {
    final instant = DateTime(2026, 9, 7, 9, 5).toUtc();

    expect(formatTime(instant), '09:05');
    expect(formatDayMonth(instant), '07.09');
  });

  test('names every weekday in Polish', () {
    // 7 to 13 September 2026 is Monday to Sunday.
    expect(
      [for (var d = 7; d <= 13; d++) formatWeekday(l10n, DateTime(2026, 9, d, 12))],
      [
        'pn',
        'wt',
        'śr',
        'czw',
        'pt',
        'sob',
        'nd',
      ],
    );
  });

  test('reads a booking like the due list will', () {
    expect(formatBooking(l10n, DateTime(2026, 9, 29, 9, 30).toUtc()), 'wt 29.09, 09:30');
  });

  group('BookingDayViewModel', () {
    test('labels a day by weekday and date, and counts its visits', () {
      final day = BookingDayViewModel(date: DateTime(2026, 9, 29), visitCount: 3);

      expect(day.dateLabel(l10n), 'wt 29.09');
      expect(day.countLabel(l10n), '3 wiz.');
    });

    test('calls an empty day free', () {
      expect(
        BookingDayViewModel(date: DateTime(2026, 9, 29), visitCount: 0).countLabel(l10n),
        'wolne',
      );
    });
  });
}
