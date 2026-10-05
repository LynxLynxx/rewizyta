import 'package:equatable/equatable.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';

/// One of the technician's job lines (branża), e.g. Kominiarz. Grouping for
/// the service-type pickers.
///
/// Every trade belongs to the user. [templateKey] names the default it was
/// copied from (`chimney`), so "restore defaults" re-inserts only what is
/// missing; it is null for a trade the user created.
final class const Trade({
  required final String id,
  required final String name,
  required final DateTime createdAt,
  required final DateTime updatedAt,
  final String? templateKey,
  final int sortOrder = 0,
  final bool isArchived = false,
  final DateTime? deletedAt,
}) with Equatable {
  bool get isDeleted => deletedAt != null;

  Trade copyWith({
    String? name,
    int? sortOrder,
    bool? isArchived,
    DateTime? updatedAt,
    Optional<DateTime>? deletedAt,
  }) {
    return Trade(
      id: id,
      name: name ?? this.name,
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
    templateKey,
    sortOrder,
    isArchived,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
