import 'package:equatable/equatable.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';

/// A kind of service the technician sells, with its cycle, e.g. "Przegląd
/// kominiarski" every 12 months. The cycle drives every due date of the
/// equipment that points at it.
///
/// Like `Trade`, each user owns their rows; [templateKey] (`chimney.inspection`)
/// is the default it was copied from, null for a user-created type. An
/// archived type is hidden from pickers but keeps its history.
final class const ServiceType({
  required final String id,
  required final String name,
  required final int cycleMonths,
  required final DateTime createdAt,
  required final DateTime updatedAt,
  final String? tradeId,
  final int? defaultPriceGrosze,
  final String? templateKey,
  final int sortOrder = 0,
  final bool isArchived = false,
  final DateTime? deletedAt,
}) with Equatable {
  bool get isDeleted => deletedAt != null;

  ServiceType copyWith({
    String? name,
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
      name: name ?? this.name,
      cycleMonths: cycleMonths ?? this.cycleMonths,
      tradeId: tradeId.dataOr(this.tradeId),
      defaultPriceGrosze: defaultPriceGrosze.dataOr(this.defaultPriceGrosze),
      templateKey: templateKey,
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
    templateKey,
    sortOrder,
    isArchived,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
