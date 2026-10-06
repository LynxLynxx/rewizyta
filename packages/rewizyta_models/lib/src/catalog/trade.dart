import 'package:equatable/equatable.dart';
import 'package:rewizyta_models/src/catalog/default_catalog.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';

/// One of the technician's job lines (branża), e.g. Kominiarz. Grouping for
/// the service-type pickers.
///
/// Every trade belongs to the user. [template] is the default it was copied
/// from, so "restore defaults" re-inserts only what is missing; it is null for
/// a trade the user created. [name] is null while a default keeps its
/// localized name, and set once the user renames it; one of the two is
/// always set.
final class const Trade({
  required final String id,
  required final DateTime createdAt,
  required final DateTime updatedAt,
  final String? name,
  final TradeTemplate? template,
  final int sortOrder = 0,
  final bool isArchived = false,
  final DateTime? deletedAt,
}) with Equatable {
  this : assert(name != null || template != null, 'A trade needs a name or a template');

  bool get isDeleted => deletedAt != null;

  Trade copyWith({
    Optional<String>? name,
    int? sortOrder,
    bool? isArchived,
    DateTime? updatedAt,
    Optional<DateTime>? deletedAt,
  }) {
    return Trade(
      id: id,
      name: name.dataOr(this.name),
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
    template,
    sortOrder,
    isArchived,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
