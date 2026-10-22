import 'package:flutter_test/flutter_test.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

void main() {
  final now = DateTime.utc(2026);
  final jan = ClientListItemViewModel.fromDomain(
    Client(
      id: '1',
      name: 'Jan Kowalski',
      phone: '+48601234567',
      addressLine: 'ul. Leśna 12',
      postalCode: '34-400',
      town: 'Łódź',
      createdAt: now,
      updatedAt: now,
    ),
  );

  test('puts the address on one line', () {
    expect(jan.addressLabel, 'ul. Leśna 12, 34-400 Łódź');
    expect(
      ClientListItemViewModel.fromDomain(
        Client(id: '2', name: 'Anna', town: 'Nysa', createdAt: now, updatedAt: now),
      ).addressLabel,
      'Nysa',
    );
    expect(
      ClientListItemViewModel.fromDomain(
        Client(id: '3', name: 'Ewa', createdAt: now, updatedAt: now),
      ).addressLabel,
      isNull,
    );
  });

  group('matches', () {
    test('everything on an empty query', () {
      expect(jan.matches('  '), isTrue);
    });

    test('name and address without case or diacritics', () {
      expect(jan.matches('kowal'), isTrue);
      expect(jan.matches('LODZ'), isTrue);
      expect(jan.matches('leśna'), isTrue);
      expect(jan.matches('nowak'), isFalse);
    });

    test('the phone whatever the spacing', () {
      expect(jan.matches('601 234'), isTrue);
      expect(jan.matches('601234567'), isTrue);
      expect(jan.matches('+48 601'), isTrue);
      expect(jan.matches('602'), isFalse);
    });

    test('digits inside a text query only against the address', () {
      expect(jan.matches('Leśna 12'), isTrue);
      expect(jan.matches('Leśna 601'), isFalse);
    });
  });

  test('LocalizedException.create maps known exceptions and wraps the rest', () {
    expect(
      LocalizedException.create(const ClientNotFoundException('x')),
      isA<LocalizedClientNotFoundException>(),
    );
    expect(LocalizedException.create(StateError('boom')), isA<LocalizedUnknownException>());
  });
}
