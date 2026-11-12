import 'package:flutter_test/flutter_test.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

void main() {
  final now = DateTime.utc(2026);

  test('formats the phone and the address', () {
    final vm = ClientDetailViewModel.fromDomain(
      Client(
        id: '1',
        name: 'Jan',
        phone: '+48601234567',
        addressLine: 'ul. Leśna 12',
        town: 'Nowy Targ',
        note: 'Pies',
        createdAt: now,
        updatedAt: now,
      ),
      today: now,
    );

    expect(vm.phone, '+48601234567');
    expect(vm.phoneLabel, '601 234 567');
    expect(vm.addressLabel, 'ul. Leśna 12, Nowy Targ');
    expect(vm.note, 'Pies');
  });

  test('leaves missing fields null', () {
    final vm = ClientDetailViewModel.fromDomain(
      Client(id: '1', name: 'Jan', createdAt: now, updatedAt: now),
      today: now,
    );

    expect([vm.phone, vm.phoneLabel, vm.addressLabel, vm.note], everyElement(isNull));
  });

  test('maps the equipment and takes the status from the earliest due date', () {
    final today = DateTime.utc(2026, 11, 4);
    final vm = ClientDetailViewModel.fromDomain(
      Client(id: '1', name: 'Jan', createdAt: now, updatedAt: now),
      today: today,
      serviceTypes: [
        ServiceType(id: 's', name: 'Komin', cycleMonths: 12, createdAt: now, updatedAt: now),
      ],
      equipment: [
        Equipment(
          id: 'later',
          clientId: '1',
          serviceTypeId: 's',
          label: 'Kuchnia',
          lastVisitAt: DateTime.utc(2026, 2),
          nextDueAt: DateTime.utc(2027, 2),
          createdAt: now,
          updatedAt: now,
        ),
        Equipment(
          id: 'overdue',
          clientId: '1',
          serviceTypeId: 'deleted-type',
          lastVisitAt: DateTime.utc(2025, 11, 2),
          nextDueAt: DateTime.utc(2026, 11, 2),
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    expect(vm.status, const DueStatusViewModel(kind: DueStatusKind.overdue, count: 2));
    expect(vm.equipment.first.serviceType?.name, 'Komin');
    expect(vm.equipment.first.label, 'Kuchnia');
    expect(vm.equipment.first.lastVisitLabel, '01.02.2026');
    expect(vm.equipment.first.nextDueLabel, '01.02.2027');
    expect(vm.equipment.last.serviceType, isNull);
  });

  test('leaves deleted equipment out of the list and the status, not out of the history', () {
    final today = DateTime.utc(2026, 11, 4);
    Equipment item(String id, {DateTime? nextDueAt, DateTime? deletedAt}) => Equipment(
      id: id,
      clientId: '1',
      serviceTypeId: 's',
      label: id,
      nextDueAt: nextDueAt,
      createdAt: now,
      updatedAt: now,
      deletedAt: deletedAt,
    );
    VisitItem visitItem(String visitId, String equipmentId) => VisitItem(
      id: '$visitId-$equipmentId',
      visitId: visitId,
      equipmentId: equipmentId,
      createdAt: now,
      updatedAt: now,
    );
    final vm = ClientDetailViewModel.fromDomain(
      Client(id: '1', name: 'Jan', createdAt: now, updatedAt: now),
      today: today,
      serviceTypes: [
        ServiceType(id: 's', name: 'Komin', cycleMonths: 12, createdAt: now, updatedAt: now),
      ],
      equipment: [
        item('Kuchnia', nextDueAt: DateTime.utc(2027, 6)),
        item('Piwnica', nextDueAt: DateTime.utc(2026), deletedAt: now),
      ],
      visits: [
        Visit(
          id: 'new',
          clientId: '1',
          doneAt: DateTime.utc(2026, 10, 2),
          priceGrosze: 18050,
          note: 'Sadza',
          createdAt: now,
          updatedAt: now,
        ),
        Visit(
          id: 'old',
          clientId: '1',
          doneAt: DateTime.utc(2025, 3),
          createdAt: now,
          updatedAt: now,
        ),
      ],
      visitItems: [
        visitItem('new', 'Piwnica'),
        visitItem('new', 'Kuchnia'),
        visitItem('gone', 'Kuchnia'),
      ],
    );

    expect(vm.equipment.map((e) => e.label), ['Kuchnia']);
    expect(vm.status?.kind, DueStatusKind.later);
    expect(vm.history.map((v) => v.id), ['new', 'old']);
    final latest = vm.history.first;
    expect(latest.dateLabel, '02.10.2026');
    expect(latest.work.map((e) => e.label), ['Kuchnia', 'Piwnica']);
    expect(latest.priceLabel, '180,50');
    expect(latest.note, 'Sadza');
    expect(vm.history.last.work, isEmpty);
    expect(vm.history.last.priceLabel, isNull);
  });
}
