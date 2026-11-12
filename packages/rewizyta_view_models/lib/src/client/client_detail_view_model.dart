import 'package:equatable/equatable.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/src/client/client_equipment_view_model.dart';
import 'package:rewizyta_view_models/src/client/client_visit_view_model.dart';
import 'package:rewizyta_view_models/src/due/due_status_view_model.dart';
import 'package:rewizyta_view_models/src/formatters/address_formatter.dart';
import 'package:rewizyta_view_models/src/formatters/phone_formatter.dart';

/// The client card (`/clients/:id`).
final class const ClientDetailViewModel({
  required final String id,
  required final String name,
  required final String? phone,
  required final String? phoneLabel,
  required final String? addressLabel,
  required final String? note,

  /// Null for a client with no equipment.
  final DueStatusViewModel? status,
  final List<ClientEquipmentViewModel> equipment = const [],

  /// The visits, newest first.
  final List<ClientVisitViewModel> history = const [],
}) with Equatable {
  /// [equipment] may include soft-deleted rows: they leave the status and the
  /// equipment list but still name the work in the [history] of [visits].
  factory fromDomain(
    Client client, {
    List<Equipment> equipment = const [],
    List<ServiceType> serviceTypes = const [],
    List<Visit> visits = const [],
    List<VisitItem> visitItems = const [],
    required DateTime today,
  }) {
    final live = [
      for (final item in equipment)
        if (!item.isDeleted) item,
    ];
    return ClientDetailViewModel(
      id: client.id,
      name: client.name,
      phone: client.phone,
      phoneLabel: client.phone == null ? null : formatPhone(client.phone!),
      addressLabel: formatAddress(
        addressLine: client.addressLine,
        postalCode: client.postalCode,
        town: client.town,
      ),
      note: client.note,
      status: DueStatusViewModel.ofClient(live, today),
      equipment: [
        for (final item in live) ClientEquipmentViewModel.fromDomain(item, serviceTypes, today),
      ],
      history: [
        for (final visit in visits)
          ClientVisitViewModel.fromDomain(
            visit,
            items: visitItems,
            equipment: equipment,
            serviceTypes: serviceTypes,
            today: today,
          ),
      ],
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    phoneLabel,
    addressLabel,
    note,
    status,
    equipment,
    history,
  ];
}
