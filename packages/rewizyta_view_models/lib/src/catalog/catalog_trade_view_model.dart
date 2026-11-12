import 'package:equatable/equatable.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/src/catalog/catalog_template_x.dart';
import 'package:rewizyta_view_models/src/catalog/service_type_view_model.dart';

/// A trade (branża) in the catalogue editor, with its service types.
final class const CatalogTradeViewModel({
  required final String id,
  final String? name,
  final TradeTemplate? template,
  final List<ServiceTypeViewModel> serviceTypes = const [],
}) with Equatable {
  /// Keeps the types of [trade] from [serviceTypes], in their order. A type
  /// whose trade is not live shows under no trade; that needs a deleted trade
  /// or a sync from elsewhere, neither of which exists yet.
  factory fromDomain(Trade trade, List<ServiceType> serviceTypes) => CatalogTradeViewModel(
    id: trade.id,
    name: trade.name,
    template: trade.template,
    serviceTypes: [
      for (final type in serviceTypes)
        if (type.tradeId == trade.id) ServiceTypeViewModel.fromDomain(type),
    ],
  );

  /// The user's name for the trade, or the default's until they rename it.
  String localizedName(AppLocalizations l10n) => name ?? template!.localizedName(l10n);

  @override
  List<Object?> get props => [id, name, template, serviceTypes];
}
