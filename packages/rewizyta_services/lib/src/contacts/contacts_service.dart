import 'package:equatable/equatable.dart';

/// A contact the user picked, as the client form needs it; what it lacks is
/// null.
final class const PickedContact({
  required final String name,
  final String? phone,
  final String? addressLine,
  final String? postalCode,
  final String? town,
}) with Equatable {
  @override
  List<Object?> get props => [name, phone, addressLine, postalCode, town];
}

/// The phone's contact book behind a vendor-agnostic interface. Only the
/// contact the user picks is read; nothing is imported in bulk.
abstract interface class ContactsService() {
  /// Whether [pickContact] may read the picked contact's phone and address.
  /// Android asks for READ_CONTACTS the first time; false once refused.
  Future<bool> requestPermission();

  /// Opens the system contact picker. Null when the user backs out.
  Future<PickedContact?> pickContact();
}
