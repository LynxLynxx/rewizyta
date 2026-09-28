import 'package:flutter_test/flutter_test.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

void main() {
  final now = DateTime.utc(2026);

  test('formats a Polish number for display', () {
    final vm = ClientListItemViewModel.fromDomain(
      Client(id: '1', name: 'Jan', phone: '+48601234567', createdAt: now, updatedAt: now),
    );
    expect(vm.phoneLabel, '601 234 567');
  });

  test('leaves the label null without a phone', () {
    final vm = ClientListItemViewModel.fromDomain(
      Client(id: '1', name: 'Jan', createdAt: now, updatedAt: now),
    );
    expect(vm.phoneLabel, isNull);
  });

  test('LocalizedException.create maps known exceptions and wraps the rest', () {
    expect(
      LocalizedException.create(const ClientNotFoundException('x')),
      isA<LocalizedClientNotFoundException>(),
    );
    expect(LocalizedException.create(StateError('boom')), isA<LocalizedUnknownException>());
  });
}
