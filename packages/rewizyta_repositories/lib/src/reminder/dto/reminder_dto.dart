import 'package:json_annotation/json_annotation.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';

part 'reminder_dto.g.dart';

/// Wire shape of a `reminders` row for `sync_push` / `sync_pull`.
@JsonSerializable()
final class const ReminderDto({
  required final String id,
  required final String clientId,
  required final String kind,
  required final String sendAt,
  required final String phone,
  required final String body,
  required final String status,
  required final String createdAt,
  required final String updatedAt,
  final String? userId,
  final String? equipmentId,
  final String? appointmentId,
  final String? dueOn,
  final int? offsetDays,
  final String? providerMessageId,
  final String? sentAt,
  final String? error,
  final String? deletedAt,
}) {
  factory fromJson(Map<String, dynamic> json) => _$ReminderDtoFromJson(json);

  factory fromDomain(Reminder reminder, {String? userId}) => ReminderDto(
    id: reminder.id,
    userId: userId,
    clientId: reminder.clientId,
    kind: enumToSql(reminder.kind),
    equipmentId: reminder.equipmentId,
    appointmentId: reminder.appointmentId,
    dueOn: reminder.dueOn == null ? null : formatDate(reminder.dueOn!),
    offsetDays: reminder.offsetDays,
    sendAt: formatTimestamp(reminder.sendAt),
    phone: reminder.phone,
    body: reminder.body,
    status: enumToSql(reminder.status),
    providerMessageId: reminder.providerMessageId,
    sentAt: reminder.sentAt == null ? null : formatTimestamp(reminder.sentAt!),
    error: reminder.error,
    createdAt: formatTimestamp(reminder.createdAt),
    updatedAt: formatTimestamp(reminder.updatedAt),
    deletedAt: reminder.deletedAt == null ? null : formatTimestamp(reminder.deletedAt!),
  );

  Map<String, dynamic> toJson() => _$ReminderDtoToJson(this);

  Reminder toDomain() => Reminder(
    id: id,
    clientId: clientId,
    kind: const EnumConverter(ReminderKind.values).fromSql(kind),
    equipmentId: equipmentId,
    appointmentId: appointmentId,
    dueOn: dueOn == null ? null : parseDate(dueOn!),
    offsetDays: offsetDays,
    sendAt: parseTimestamp(sendAt),
    phone: phone,
    body: body,
    status: const EnumConverter(ReminderStatus.values).fromSql(status),
    providerMessageId: providerMessageId,
    sentAt: sentAt == null ? null : parseTimestamp(sentAt!),
    error: error,
    createdAt: parseTimestamp(createdAt),
    updatedAt: parseTimestamp(updatedAt),
    deletedAt: deletedAt == null ? null : parseTimestamp(deletedAt!),
  );
}
