import 'package:equatable/equatable.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_models/rewizyta_models.dart';

enum DueStatusKind() {
  overdue,
  today,
  soon,
  later,
  none,
}

/// The status tag: one rule for every list and tag (`docs/DESIGN_BRIEF.md`,
/// "Status"). [count] is days, or months for [DueStatusKind.later].
final class const DueStatusViewModel({required final DueStatusKind kind, final int count = 0})
    with Equatable {
  factory fromDate(DateTime? nextDueAt, DateTime today) {
    if (nextDueAt == null) return const DueStatusViewModel(kind: DueStatusKind.none);
    final days = nextDueAt.difference(today).inDays;
    return switch (days) {
      < 0 => DueStatusViewModel(kind: DueStatusKind.overdue, count: -days),
      0 => const DueStatusViewModel(kind: DueStatusKind.today),
      <= 60 => DueStatusViewModel(kind: DueStatusKind.soon, count: days),
      _ => DueStatusViewModel(kind: DueStatusKind.later, count: (days / 30).round()),
    };
  }

  /// A client's status is that of its earliest due equipment. Null for a
  /// client with no equipment, which has nothing to be due.
  static DueStatusViewModel? ofClient(List<Equipment> equipment, DateTime today) {
    if (equipment.isEmpty) return null;
    final dates = equipment.map((item) => item.nextDueAt).nonNulls;
    return DueStatusViewModel.fromDate(
      dates.isEmpty ? null : dates.reduce((a, b) => a.isBefore(b) ? a : b),
      today,
    );
  }

  /// Overdue or due within 60 days: what the due list shows.
  bool get isDue => switch (kind) {
    DueStatusKind.overdue || DueStatusKind.today || DueStatusKind.soon => true,
    DueStatusKind.later || DueStatusKind.none => false,
  };

  String localizedLabel(AppLocalizations l10n) => switch (kind) {
    DueStatusKind.overdue => l10n.dueOverdue(count),
    DueStatusKind.today => l10n.dueToday,
    DueStatusKind.soon => l10n.dueInDays(count),
    DueStatusKind.later => l10n.dueInMonths(count),
    DueStatusKind.none => l10n.dueNone,
  };

  @override
  List<Object?> get props => [kind, count];
}
