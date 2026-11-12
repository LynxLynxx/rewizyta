import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:rewizyta_services/rewizyta_services.dart';

/// The system contact picker through flutter_contacts. Only the picked
/// contact is read; its device id is not kept.
final class const FlutterContactsService() implements ContactsService {
  /// The picker needs no permission, but on Android reading the picked
  /// contact's phone and address does. iOS hands them over without one.
  @override
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;
    return await FlutterContacts.permissions.request(PermissionType.read) ==
        PermissionStatus.granted;
  }

  @override
  Future<PickedContact?> pickContact() async {
    final contact = await FlutterContacts.native.showPicker(
      properties: {ContactProperty.phone, ContactProperty.address},
    );
    return contact == null ? null : pickedContactFrom(contact);
  }
}

/// What iOS ("iPhone") and Android ("work mobile") also label a mobile number.
const _mobileLabels = {PhoneLabel.mobile, PhoneLabel.iPhone, PhoneLabel.workMobile};

/// The mobile number if the contact has one (the SMS reminders need one),
/// else the first; the first address. The phone goes as stored, since the
/// clients service normalises it on save. Android often keeps a whole typed
/// address, line breaks included, in one field, so the address line is folded
/// onto one line.
@visibleForTesting
PickedContact pickedContactFrom(Contact contact) {
  final phones = contact.phones;
  final phone =
      phones.where((phone) => _mobileLabels.contains(phone.label.label)).firstOrNull ??
      phones.firstOrNull;
  final address = contact.addresses.firstOrNull;
  final street = _clean(address?.street);
  final postalCode = _clean(address?.postalCode);
  final town = _clean(address?.city);
  final hasParts = street != null || postalCode != null || town != null;
  return PickedContact(
    name: _clean(contact.displayName) ?? '',
    phone: _clean(phone?.number),
    addressLine: hasParts ? street : _clean(address?.formatted),
    postalCode: postalCode,
    town: town,
  );
}

final _lineBreaks = RegExp(r'\s*\n\s*');

/// Trimmed and on one line, or null when nothing is left.
String? _clean(String? value) {
  final text = value?.trim().replaceAll(_lineBreaks, ', ');
  return text == null || text.isEmpty ? null : text;
}
