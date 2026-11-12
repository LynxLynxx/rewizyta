import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewizyta/app/integrations/flutter_contacts_service.dart';
import 'package:rewizyta_services/rewizyta_services.dart';

void main() {
  group('pickedContactFrom', () {
    test('takes the mobile number over a home number listed first', () {
      const contact = Contact(
        displayName: 'Jan Kowalski',
        phones: [
          Phone(number: '600 000 000', label: Label(PhoneLabel.home)),
          Phone(number: '+48 601 234 567', label: Label(PhoneLabel.mobile)),
        ],
        addresses: [Address(street: 'ul. Leśna 12', postalCode: '48-300', city: 'Nysa')],
      );

      expect(
        pickedContactFrom(contact),
        const PickedContact(
          name: 'Jan Kowalski',
          phone: '+48 601 234 567',
          addressLine: 'ul. Leśna 12',
          postalCode: '48-300',
          town: 'Nysa',
        ),
      );
    });

    test('takes an iPhone or a work mobile number as the mobile one', () {
      for (final label in [PhoneLabel.iPhone, PhoneLabel.workMobile]) {
        final contact = Contact(
          displayName: 'Jan',
          phones: [
            const Phone(number: '600 000 000', label: Label(PhoneLabel.home)),
            Phone(number: '+48 601 234 567', label: Label(label)),
          ],
        );

        expect(pickedContactFrom(contact).phone, '+48 601 234 567', reason: label.name);
      }
    });

    test('without a mobile number takes the first one', () {
      const contact = Contact(
        displayName: 'Jan',
        phones: [
          Phone(number: '600 000 000', label: Label(PhoneLabel.home)),
          Phone(number: '+48 601 234 567', label: Label(PhoneLabel.work)),
        ],
      );

      expect(pickedContactFrom(contact).phone, '600 000 000');
    });

    test('an address typed as one block lands on one line', () {
      const formattedOnly = Contact(
        displayName: 'Jan',
        addresses: [Address(formatted: 'ul. Leśna 12\n48-300 Nysa')],
      );
      const inStreet = Contact(
        displayName: 'Jan',
        addresses: [Address(street: 'ul. Leśna 12\r\n48-300 Nysa ')],
      );

      for (final contact in [formattedOnly, inStreet]) {
        expect(
          pickedContactFrom(contact),
          const PickedContact(name: 'Jan', addressLine: 'ul. Leśna 12, 48-300 Nysa'),
        );
      }
    });

    test('a contact with only a name maps the rest to null', () {
      expect(
        pickedContactFrom(const Contact(displayName: 'Jan')),
        const PickedContact(name: 'Jan'),
      );
      expect(pickedContactFrom(const Contact()), const PickedContact(name: ''));
    });
  });
}
