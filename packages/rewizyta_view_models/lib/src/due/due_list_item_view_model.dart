import 'package:equatable/equatable.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/src/catalog/service_type_view_model.dart';
import 'package:rewizyta_view_models/src/due/due_status_view_model.dart';

/// A client on the due list: due within 60 days or overdue.
final class const DueListItemViewModel({
  required final String id,
  required final String name,
  required final DueStatusViewModel status,
  final String? town,

  /// E.164, for the "Dzwoń" button; null hides it.
  final String? phone,

  /// The service types of the equipment that is due, each once.
  final List<ServiceTypeViewModel> services = const [],
}) with Equatable {
  /// Null when nothing of the client's is due within 60 days, so the client
  /// does not belong on the list.
  static DueListItemViewModel? fromDomain(
    Client client, {
    required List<Equipment> equipment,
    required List<ServiceType> serviceTypes,
    required DateTime today,
  }) {
    final status = DueStatusViewModel.ofClient(equipment, today);
    if (status == null || !status.isDue) return null;
    final dueTypeIds = {
      for (final item in equipment)
        if (DueStatusViewModel.fromDate(item.nextDueAt, today).isDue) item.serviceTypeId,
    };
    return DueListItemViewModel(
      id: client.id,
      name: client.name,
      status: status,
      town: client.town,
      phone: client.phone,
      services: [
        for (final type in serviceTypes)
          if (dueTypeIds.contains(type.id)) ServiceTypeViewModel.fromDomain(type),
      ],
    );
  }

  /// "town · service, service", or null when neither is known.
  String? subtitle(AppLocalizations l10n) {
    final services = this.services.map((type) => type.localizedName(l10n)).join(', ');
    final parts = [?town, if (services.isNotEmpty) services];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  List<Object?> get props => [id, name, status, town, phone, services];
}
