import 'package:equatable/equatable.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/src/catalog/service_type_view_model.dart';
import 'package:rewizyta_view_models/src/due/due_status_view_model.dart';
import 'package:rewizyta_view_models/src/formatters/date_formatter.dart';

/// One piece of equipment on the client card.
final class const ClientEquipmentViewModel({
  required final String id,
  required final DueStatusViewModel status,

  /// Null when the row points at a soft-deleted service type.
  final ServiceTypeViewModel? serviceType,
  final String? label,
  final String? lastVisitLabel,
  final String? nextDueLabel,
}) with Equatable {
  factory fromDomain(Equipment equipment, List<ServiceType> serviceTypes, DateTime today) {
    final type = serviceTypes.where((type) => type.id == equipment.serviceTypeId).firstOrNull;
    return ClientEquipmentViewModel(
      id: equipment.id,
      status: DueStatusViewModel.fromDate(equipment.nextDueAt, today),
      serviceType: type == null ? null : ServiceTypeViewModel.fromDomain(type),
      label: equipment.label,
      lastVisitLabel: equipment.lastVisitAt == null ? null : formatDate(equipment.lastVisitAt!),
      nextDueLabel: equipment.nextDueAt == null ? null : formatDate(equipment.nextDueAt!),
    );
  }

  /// "Przegląd przewodów kominowych · Kuchnia": the service and the label, as
  /// on a chip or a history row.
  String workLabel(AppLocalizations l10n) =>
      [?serviceType?.localizedName(l10n), ?label].join(' · ');

  @override
  List<Object?> get props => [id, status, serviceType, label, lastVisitLabel, nextDueLabel];
}
