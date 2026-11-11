import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

void main() {
  final now = DateTime.utc(2026);
  final today = DateTime.utc(2026, 11, 4);
  final l10n = lookupAppLocalizations(const Locale('pl'));
  final client = Client(
    id: 'c1',
    name: 'Jan',
    phone: '+48601234567',
    town: 'Nysa',
    createdAt: now,
    updatedAt: now,
  );
  final chimney = ServiceType(
    id: 's1',
    cycleMonths: 12,
    template: ServiceTypeTemplate.chimneyInspection,
    createdAt: now,
    updatedAt: now,
  );
  final boiler = ServiceType(
    id: 's2',
    cycleMonths: 12,
    name: 'Kocioł',
    createdAt: now,
    updatedAt: now,
  );

  Equipment equipment(String id, String serviceTypeId, DateTime? nextDueAt) => Equipment(
    id: id,
    clientId: 'c1',
    serviceTypeId: serviceTypeId,
    nextDueAt: nextDueAt,
    createdAt: now,
    updatedAt: now,
  );

  DueListItemViewModel? build(List<Equipment> items) => DueListItemViewModel.fromDomain(
    client,
    equipment: items,
    serviceTypes: [chimney, boiler],
    today: today,
  );

  test('takes the earliest status and names only the due services', () {
    final vm = build([
      equipment('e1', 's1', DateTime.utc(2026, 10, 30)),
      equipment('e2', 's2', DateTime.utc(2027, 6)),
    ])!;

    expect(vm.status, const DueStatusViewModel(kind: DueStatusKind.overdue, count: 5));
    expect(vm.phone, '+48601234567');
    expect(vm.subtitle(l10n), 'Nysa · Przegląd przewodów kominowych');
  });

  test('names each due service type once', () {
    final vm = build([
      equipment('e1', 's1', DateTime.utc(2026, 11, 4)),
      equipment('e2', 's1', DateTime.utc(2026, 12)),
      equipment('e3', 's2', DateTime.utc(2027, 1, 3)),
    ])!;

    expect(vm.status.kind, DueStatusKind.today);
    expect(vm.subtitle(l10n), 'Nysa · Przegląd przewodów kominowych, Kocioł');
  });

  test('is null when nothing is due within 60 days', () {
    expect(build([]), isNull);
    expect(build([equipment('e1', 's1', null)]), isNull);
    expect(build([equipment('e1', 's1', DateTime.utc(2027, 1, 4))]), isNull);
  });

  test('the subtitle drops what is unknown', () {
    const bare = DueListItemViewModel(
      id: 'c1',
      name: 'Jan',
      status: DueStatusViewModel(kind: DueStatusKind.today),
    );
    expect(bare.subtitle(l10n), isNull);
  });
}
