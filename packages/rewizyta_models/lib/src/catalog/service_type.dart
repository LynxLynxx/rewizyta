import 'package:equatable/equatable.dart';
import 'package:rewizyta_models/src/catalog/default_catalog.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';

/// A kind of service the technician sells, with its cycle, e.g. "Przegląd
/// kominiarski" every 12 months. The cycle drives every due date of the
/// equipment that points at it.
///
/// Like `Trade`, each user owns their rows; [template] is the default it was
/// copied from, null for a user-created type, and [name] is null while a
/// default keeps its localized name. An archived type is hidden from pickers
/// but keeps its history.
final class const ServiceType({
  required final String id,
  required final int cycleMonths,
  required final DateTime createdAt,
  required final DateTime updatedAt,
  final String? name,
  final String? tradeId,
  final int? defaultPriceGrosze,
  final ServiceTypeTemplate? template,
  final int sortOrder = 0,
  final bool isArchived = false,
  final DateTime? deletedAt,
}) with Equatable {
  this : assert(name != null || template != null, 'A service type needs a name or a template');

  bool get isDeleted => deletedAt != null;

  ServiceType copyWith({
    Optional<String>? name,
    int? cycleMonths,
    Optional<String>? tradeId,
    Optional<int>? defaultPriceGrosze,
    int? sortOrder,
    bool? isArchived,
    DateTime? updatedAt,
    Optional<DateTime>? deletedAt,
  }) {
    return ServiceType(
      id: id,
      name: name.dataOr(this.name),
      cycleMonths: cycleMonths ?? this.cycleMonths,
      tradeId: tradeId.dataOr(this.tradeId),
      defaultPriceGrosze: defaultPriceGrosze.dataOr(this.defaultPriceGrosze),
      template: template,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt.dataOr(this.deletedAt),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    cycleMonths,
    tradeId,
    defaultPriceGrosze,
    template,
    sortOrder,
    isArchived,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
