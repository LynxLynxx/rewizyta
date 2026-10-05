import 'package:equatable/equatable.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';

/// A visit at a client on [doneAt] (a calendar day, `DateTime.utc(y, m, d)`).
/// What was serviced is the visit's `VisitItem`s. [appointmentId] is the
/// booking this visit fulfilled, if any.
final class const Visit({
  required final String id,
  required final String clientId,
  required final DateTime doneAt,
  required final DateTime createdAt,
  required final DateTime updatedAt,
  final int? priceGrosze,
  final String? note,
  final String? appointmentId,
  final DateTime? deletedAt,
}) with Equatable {
  bool get isDeleted => deletedAt != null;

  Visit copyWith({
    DateTime? doneAt,
    Optional<int>? priceGrosze,
    Optional<String>? note,
    Optional<String>? appointmentId,
    DateTime? updatedAt,
    Optional<DateTime>? deletedAt,
  }) {
    return Visit(
      id: id,
      clientId: clientId,
      doneAt: doneAt ?? this.doneAt,
      priceGrosze: priceGrosze.dataOr(this.priceGrosze),
      note: note.dataOr(this.note),
      appointmentId: appointmentId.dataOr(this.appointmentId),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt.dataOr(this.deletedAt),
    );
  }

  @override
  List<Object?> get props => [
    id,
    clientId,
    doneAt,
    priceGrosze,
    note,
    appointmentId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
