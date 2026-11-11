import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

void main() {
  final today = DateTime.utc(2026, 11, 4);
  DueStatusViewModel inDays(int days) =>
      DueStatusViewModel.fromDate(today.add(Duration(days: days)), today);
  Equipment item(DateTime? nextDueAt) => Equipment(
    id: 'e',
    clientId: 'c',
    serviceTypeId: 's',
    nextDueAt: nextDueAt,
    createdAt: today,
    updatedAt: today,
  );

  test('follows the rule in the design brief at each boundary', () {
    expect(inDays(-1), const DueStatusViewModel(kind: DueStatusKind.overdue, count: 1));
    expect(inDays(0), const DueStatusViewModel(kind: DueStatusKind.today));
    expect(inDays(1), const DueStatusViewModel(kind: DueStatusKind.soon, count: 1));
    expect(inDays(60), const DueStatusViewModel(kind: DueStatusKind.soon, count: 60));
    expect(inDays(61), const DueStatusViewModel(kind: DueStatusKind.later, count: 2));
    expect(
      DueStatusViewModel.fromDate(null, today),
      const DueStatusViewModel(kind: DueStatusKind.none),
    );
  });

  test('isDue covers overdue through 60 days', () {
    expect([-1, 0, 60].map((days) => inDays(days).isDue), everyElement(isTrue));
    expect(inDays(61).isDue, isFalse);
    expect(DueStatusViewModel.fromDate(null, today).isDue, isFalse);
  });

  group('ofClient', () {
    test('is null without equipment and none without any due date', () {
      expect(DueStatusViewModel.ofClient(const [], today), isNull);
      expect(
        DueStatusViewModel.ofClient([item(null)], today),
        const DueStatusViewModel(kind: DueStatusKind.none),
      );
    });

    test('takes the earliest due date, ignoring rows without one', () {
      expect(
        DueStatusViewModel.ofClient([
          item(null),
          item(DateTime.utc(2027, 6)),
          item(DateTime.utc(2026, 11, 5)),
        ], today),
        const DueStatusViewModel(kind: DueStatusKind.soon, count: 1),
      );
    });
  });

  test('labels read as in the design, with the Polish plural', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('pl'));
    String label(DueStatusKind kind, [int count = 0]) =>
        DueStatusViewModel(kind: kind, count: count).localizedLabel(l10n);

    expect(label(DueStatusKind.overdue, 1), 'po terminie 1 dzień');
    expect(label(DueStatusKind.overdue, 5), 'po terminie 5 dni');
    expect(label(DueStatusKind.today), 'dzisiaj');
    expect(label(DueStatusKind.soon, 1), 'za 1 dzień');
    expect(label(DueStatusKind.soon, 22), 'za 22 dni');
    expect(label(DueStatusKind.later, 11), 'za 11 mies.');
    expect(label(DueStatusKind.none), 'bez terminu');
  });
}
