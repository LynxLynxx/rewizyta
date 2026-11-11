import 'package:equatable/equatable.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/src/client/client_equipment_view_model.dart';
import 'package:rewizyta_view_models/src/due/due_status_view_model.dart';
import 'package:rewizyta_view_models/src/formatters/address_formatter.dart';
import 'package:rewizyta_view_models/src/formatters/phone_formatter.dart';

/// The client card (`/clients/:id`).
final class const ClientDetailViewModel({
  required final String id,
  required final String name,
  required final String? phoneLabel,
  required final String? addressLabel,
  required final String? note,

  /// Null for a client with no equipment.
  final DueStatusViewModel? status,
  final List<ClientEquipmentViewModel> equipment = const [],
}) with Equatable {
  factory fromDomain(
    Client client, {
    List<Equipment> equipment = const [],
    List<ServiceType> serviceTypes = const [],
    required DateTime today,
  }) => ClientDetailViewModel(
    id: client.id,
    name: client.name,
    phoneLabel: client.phone == null ? null : formatPhone(client.phone!),
    addressLabel: formatAddress(
      addressLine: client.addressLine,
      postalCode: client.postalCode,
      town: client.town,
    ),
    note: client.note,
    status: DueStatusViewModel.ofClient(equipment, today),
    equipment: [
      for (final item in equipment) ClientEquipmentViewModel.fromDomain(item, serviceTypes, today),
    ],
  );

  @override
  List<Object?> get props => [id, name, phoneLabel, addressLabel, note, status, equipment];
}
