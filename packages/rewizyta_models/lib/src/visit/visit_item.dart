import 'package:equatable/equatable.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';

/// One piece of equipment serviced during a visit. A visit has at most one
/// item per equipment; unticking soft-deletes the item and ticking again
/// restores the same row.
final class const VisitItem({
  required final String id,
  required final String visitId,
  required final String equipmentId,
  required final DateTime createdAt,
  required final DateTime updatedAt,
  final DateTime? deletedAt,
}) with Equatable {
  bool get isDeleted => deletedAt != null;

  VisitItem copyWith({DateTime? updatedAt, Optional<DateTime>? deletedAt}) {
    return VisitItem(
      id: id,
      visitId: visitId,
      equipmentId: equipmentId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt.dataOr(this.deletedAt),
    );
  }

  @override
  List<Object?> get props => [id, visitId, equipmentId, createdAt, updatedAt, deletedAt];
}
