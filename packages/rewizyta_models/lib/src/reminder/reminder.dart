import 'package:equatable/equatable.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';

/// Why a reminder exists: a service coming [due] (created by the server's
/// daily job), an [appointment] confirmation, or a [manual] message the
/// technician wrote.
enum ReminderKind() {
  due,
  appointment,
  manual,
}

/// Delivery state. Only the server moves a reminder past [pending]; the app
/// may set [cancelled].
enum ReminderStatus() {
  pending,
  sent,
  delivered,
  failed,
  cancelled,
}

/// One SMS to a client, automatic or manual. The server renders and sends it
/// (the phone never talks to an SMS gateway); the app writes manual ones and
/// pulls the rest to show the message history.
///
/// [phone] and [body] are snapshots taken when the reminder was created, i.e.
/// exactly what was sent. [dueOn] (a calendar day) and [offsetDays] are set for
/// [ReminderKind.due].
final class const Reminder({
  required final String id,
  required final String clientId,
  required final ReminderKind kind,
  required final DateTime sendAt,
  required final String phone,
  required final String body,
  required final DateTime createdAt,
  required final DateTime updatedAt,
  final ReminderStatus status = ReminderStatus.pending,
  final String? equipmentId,
  final String? appointmentId,
  final DateTime? dueOn,
  final int? offsetDays,
  final String? providerMessageId,
  final DateTime? sentAt,
  final String? error,
  final DateTime? deletedAt,
}) with Equatable {
  bool get isDeleted => deletedAt != null;

  Reminder copyWith({
    ReminderStatus? status,
    DateTime? updatedAt,
    Optional<DateTime>? deletedAt,
  }) {
    return Reminder(
      id: id,
      clientId: clientId,
      kind: kind,
      sendAt: sendAt,
      phone: phone,
      body: body,
      status: status ?? this.status,
      equipmentId: equipmentId,
      appointmentId: appointmentId,
      dueOn: dueOn,
      offsetDays: offsetDays,
      providerMessageId: providerMessageId,
      sentAt: sentAt,
      error: error,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt.dataOr(this.deletedAt),
    );
  }

  @override
  List<Object?> get props => [
    id,
    clientId,
    kind,
    sendAt,
    phone,
    body,
    status,
    equipmentId,
    appointmentId,
    dueOn,
    offsetDays,
    providerMessageId,
    sentAt,
    error,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
