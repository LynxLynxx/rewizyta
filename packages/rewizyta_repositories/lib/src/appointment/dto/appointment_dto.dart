import 'package:json_annotation/json_annotation.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';

part 'appointment_dto.g.dart';

/// Wire shape of an `appointments` row for `sync_push` / `sync_pull`.
@JsonSerializable()
final class const AppointmentDto({
  required final String id,
  required final String clientId,
  required final String startsAt,
  required final int durationMinutes,
  required final String status,
  required final bool isTimeFixed,
  required final String createdAt,
  required final String updatedAt,
  final String? userId,
  final int? routePosition,
  final String? note,
  final String? deletedAt,
}) {
  factory fromJson(Map<String, dynamic> json) => _$AppointmentDtoFromJson(json);

  factory fromDomain(Appointment appointment, {String? userId}) => AppointmentDto(
    id: appointment.id,
    userId: userId,
    clientId: appointment.clientId,
    startsAt: formatTimestamp(appointment.startsAt),
    durationMinutes: appointment.durationMinutes,
    status: enumToSql(appointment.status),
    isTimeFixed: appointment.isTimeFixed,
    routePosition: appointment.routePosition,
    note: appointment.note,
    createdAt: formatTimestamp(appointment.createdAt),
    updatedAt: formatTimestamp(appointment.updatedAt),
    deletedAt: appointment.deletedAt == null ? null : formatTimestamp(appointment.deletedAt!),
  );

  Map<String, dynamic> toJson() => _$AppointmentDtoToJson(this);

  Appointment toDomain() => Appointment(
    id: id,
    clientId: clientId,
    startsAt: parseTimestamp(startsAt),
    durationMinutes: durationMinutes,
    status: const EnumConverter(AppointmentStatus.values).fromSql(status),
    isTimeFixed: isTimeFixed,
    routePosition: routePosition,
    note: note,
    createdAt: parseTimestamp(createdAt),
    updatedAt: parseTimestamp(updatedAt),
    deletedAt: deletedAt == null ? null : parseTimestamp(deletedAt!),
  );
}
