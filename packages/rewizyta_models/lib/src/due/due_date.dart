/// Due-date rule: the next visit is the last visit plus the service cycle in
/// calendar months, clamped to the end of the target month
/// (31 January + 1 month = 28/29 February).
///
/// `next_due_at` is derived, never authored: every place that stores it is a
/// cache computed by this function (see docs/DATABASE.md, "Due dates").
DateTime nextDue(DateTime lastVisit, int cycleMonths) {
  assert(cycleMonths > 0, 'cycleMonths must be positive');
  final totalMonths = lastVisit.month - 1 + cycleMonths;
  final year = lastVisit.year + totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDayOfTargetMonth = DateTime.utc(year, month + 1, 0).day;
  final day = lastVisit.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : lastVisit.day;
  return DateTime.utc(year, month, day);
}
