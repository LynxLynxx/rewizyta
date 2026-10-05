import 'package:equatable/equatable.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';

/// A person or company the technician services.
///
/// Phone numbers are E.164 (`+48…`); addresses are free text because rural
/// Polish addresses rarely fit a street/number grid. [lat] and [lng] are
/// geocoded on the phone when the address is saved and only order the day's
/// route.
final class const Client({
  required final String id,
  required final String name,
  required final DateTime createdAt,
  required final DateTime updatedAt,
  final String? phone,
  final String? addressLine,
  final String? town,
  final String? postalCode,
  final double? lat,
  final double? lng,
  final String? note,
  final String? contactId,
  final DateTime? deletedAt,
}) with Equatable {
  bool get isDeleted => deletedAt != null;

  /// Nullable fields take an [Optional], so they can be cleared as well as
  /// set (`deletedAt: const Optional.empty()` restores a soft-deleted row).
  Client copyWith({
    String? name,
    Optional<String>? phone,
    Optional<String>? addressLine,
    Optional<String>? town,
    Optional<String>? postalCode,
    Optional<double>? lat,
    Optional<double>? lng,
    Optional<String>? note,
    Optional<String>? contactId,
    DateTime? updatedAt,
    Optional<DateTime>? deletedAt,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      phone: phone.dataOr(this.phone),
      addressLine: addressLine.dataOr(this.addressLine),
      town: town.dataOr(this.town),
      postalCode: postalCode.dataOr(this.postalCode),
      lat: lat.dataOr(this.lat),
      lng: lng.dataOr(this.lng),
      note: note.dataOr(this.note),
      contactId: contactId.dataOr(this.contactId),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt.dataOr(this.deletedAt),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    addressLine,
    town,
    postalCode,
    lat,
    lng,
    note,
    contactId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
