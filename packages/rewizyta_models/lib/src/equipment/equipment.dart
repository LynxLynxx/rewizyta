import 'package:equatable/equatable.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';

/// One serviced item at a client, e.g. "Komin – kuchnia", tied to the service
/// type that sets its cycle. [count] covers identical items (three flues).
///
/// [lastVisitAt] and [nextDueAt] are a cache of the visit history, never
/// typed by the user (docs/DATABASE.md, "Due dates"): the latest visit that
/// serviced this item, and that day plus the cycle. Both are null until the
/// first visit, which the due list shows as "due now". They change only
/// through [withDue]. Dates are `DateTime.utc(y, m, d)`.
final class const Equipment({
  required final String id,
  required final String clientId,
  required final String serviceTypeId,
  required final DateTime createdAt,
  required final DateTime updatedAt,
  final String? label,
  final int count = 1,
  final String? note,
  final DateTime? lastVisitAt,
  final DateTime? nextDueAt,
  final DateTime? deletedAt,
}) with Equatable {
  bool get isDeleted => deletedAt != null;

  Equipment copyWith({
    String? serviceTypeId,
    Optional<String>? label,
    int? count,
    Optional<String>? note,
    DateTime? updatedAt,
    Optional<DateTime>? deletedAt,
  }) {
    return Equipment(
      id: id,
      clientId: clientId,
      serviceTypeId: serviceTypeId ?? this.serviceTypeId,
      label: label.dataOr(this.label),
      count: count ?? this.count,
      note: note.dataOr(this.note),
      lastVisitAt: lastVisitAt,
      nextDueAt: nextDueAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt.dataOr(this.deletedAt),
    );
  }

  /// Replaces the cached due dates. Not part of [copyWith] because the caches
  /// are derived: only the due-date recompute sets them.
  Equipment withDue({
    required DateTime? lastVisitAt,
    required DateTime? nextDueAt,
    required DateTime updatedAt,
  }) {
    return Equipment(
      id: id,
      clientId: clientId,
      serviceTypeId: serviceTypeId,
      label: label,
      count: count,
      note: note,
      lastVisitAt: lastVisitAt,
      nextDueAt: nextDueAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    clientId,
    serviceTypeId,
    label,
    count,
    note,
    lastVisitAt,
    nextDueAt,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
