import 'package:equatable/equatable.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/src/client/client_equipment_view_model.dart';
import 'package:rewizyta_view_models/src/formatters/date_formatter.dart';
import 'package:rewizyta_view_models/src/formatters/money_formatter.dart';

/// One visit in the history on the client card.
final class const ClientVisitViewModel({
  required final String id,
  required final String dateLabel,

  /// What was serviced, in the card's equipment order. Soft-deleted
  /// equipment is named too: it was serviced all the same.
  final List<ClientEquipmentViewModel> work = const [],

  /// The amount without the currency (`180,50`), null when no price was typed.
  final String? priceLabel,
  final String? note,
}) with Equatable {
  /// [equipment] is the client's, soft-deleted rows included; [items] may hold
  /// other visits' items too.
  factory fromDomain(
    Visit visit, {
    required List<VisitItem> items,
    required List<Equipment> equipment,
    required List<ServiceType> serviceTypes,
    required DateTime today,
  }) {
    final serviced = {
      for (final item in items)
        if (item.visitId == visit.id) item.equipmentId,
    };
    return ClientVisitViewModel(
      id: visit.id,
      dateLabel: formatDate(visit.doneAt),
      work: [
        for (final item in equipment)
          if (serviced.contains(item.id))
            ClientEquipmentViewModel.fromDomain(item, serviceTypes, today),
      ],
      priceLabel: visit.priceGrosze == null ? null : formatMoney(visit.priceGrosze!),
      note: visit.note,
    );
  }

  @override
  List<Object?> get props => [id, dateLabel, work, priceLabel, note];
}
