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
    );

    expect(vm.phoneLabel, '601 234 567');
    expect(vm.addressLabel, 'ul. Leśna 12, Nowy Targ');
    expect(vm.note, 'Pies');
  });

  test('leaves missing fields null', () {
    final vm = ClientDetailViewModel.fromDomain(
      Client(id: '1', name: 'Jan', createdAt: now, updatedAt: now),
    );

    expect([vm.phoneLabel, vm.addressLabel, vm.note], everyElement(isNull));
  });
}
