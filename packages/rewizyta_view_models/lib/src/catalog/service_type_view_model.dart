import 'package:equatable/equatable.dart';
import 'package:rewizyta_localization/rewizyta_localization.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/src/catalog/catalog_template_x.dart';

/// A service type on a chip or an equipment row.
final class const ServiceTypeViewModel({
  required final String id,
  required final int cycleMonths,
  final String? name,
  final ServiceTypeTemplate? template,
  final bool isArchived = false,
}) with Equatable {
  factory fromDomain(ServiceType type) => ServiceTypeViewModel(
    id: type.id,
    cycleMonths: type.cycleMonths,
    name: type.name,
    template: type.template,
    isArchived: type.isArchived,
  );

  /// The user's name for the row, or the default's until they rename it.
  String localizedName(AppLocalizations l10n) => name ?? template!.localizedName(l10n);

  @override
  List<Object?> get props => [id, cycleMonths, name, template, isArchived];
}
