import 'package:equatable/equatable.dart';

/// One equipment row of the client form. No [id] means a new row;
/// [lastVisitAt] is a day to record as a visit, never a value for the cache on
/// `Equipment`.
final class const EquipmentDraft({
  required final String serviceTypeId,
  final String? id,
  final String? label,
  final DateTime? lastVisitAt,
}) with Equatable {
  @override
  List<Object?> get props => [id, serviceTypeId, label, lastVisitAt];
}
