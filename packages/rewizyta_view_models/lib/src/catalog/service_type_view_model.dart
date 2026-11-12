import 'package:equatable/equatable.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/src/catalog/catalog_template_x.dart';
import 'package:rewizyta_view_models/src/formatters/money_formatter.dart';

/// A service type on a chip, an equipment row or the catalogue editor.
final class const ServiceTypeViewModel({
  required final String id,
  required final int cycleMonths,
  final String? name,
  final ServiceTypeTemplate? template,
  final int? defaultPriceGrosze,
  final bool isArchived = false,
}) with Equatable {
  factory fromDomain(ServiceType type) => ServiceTypeViewModel(
    id: type.id,
    cycleMonths: type.cycleMonths,
    name: type.name,
    template: type.template,
    defaultPriceGrosze: type.defaultPriceGrosze,
    isArchived: type.isArchived,
  );

  /// The user's name for the row, or the default's until they rename it.
  String localizedName(AppLocalizations l10n) => name ?? template!.localizedName(l10n);

  /// "co 12 mies. · 180 zł · w archiwum": the row's subtitle in the editor.
  String details(AppLocalizations l10n) => [
    l10n.catalogCycle(cycleMonths),
    if (defaultPriceGrosze case final price?) l10n.visitPriceAmount(formatMoney(price)),
    if (isArchived) l10n.catalogArchived,
  ].join(' · ');

  @override
  List<Object?> get props => [id, cycleMonths, name, template, defaultPriceGrosze, isArchived];
}
