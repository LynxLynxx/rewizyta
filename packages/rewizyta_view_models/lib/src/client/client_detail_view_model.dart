import 'package:equatable/equatable.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/src/formatters/address_formatter.dart';
import 'package:rewizyta_view_models/src/formatters/phone_formatter.dart';

/// The client card (`/clients/:id`).
final class const ClientDetailViewModel({
  required final String id,
  required final String name,
  required final String? phoneLabel,
  required final String? addressLabel,
  required final String? note,
}) with Equatable {
  factory fromDomain(Client client) => ClientDetailViewModel(
    id: client.id,
    name: client.name,
    phoneLabel: client.phone == null ? null : formatPhone(client.phone!),
    addressLabel: formatAddress(
      addressLine: client.addressLine,
      postalCode: client.postalCode,
      town: client.town,
    ),
    note: client.note,
  );

  @override
  List<Object?> get props => [id, name, phoneLabel, addressLabel, note];
}
