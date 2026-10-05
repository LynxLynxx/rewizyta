import 'package:json_annotation/json_annotation.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';

part 'visit_dto.g.dart';

/// Wire shape of a `visits` row for `sync_push` / `sync_pull`.
@JsonSerializable()
final class const VisitDto({
  required final String id,
  required final String clientId,
  required final String doneAt,
  required final String createdAt,
  required final String updatedAt,
  final String? userId,
  final int? priceGrosze,
  final String? note,
  final String? appointmentId,
  final String? deletedAt,
}) {
  factory fromJson(Map<String, dynamic> json) => _$VisitDtoFromJson(json);

  factory fromDomain(Visit visit, {String? userId}) => VisitDto(
    id: visit.id,
    userId: userId,
    clientId: visit.clientId,
    doneAt: formatDate(visit.doneAt),
    priceGrosze: visit.priceGrosze,
    note: visit.note,
    appointmentId: visit.appointmentId,
    createdAt: formatTimestamp(visit.createdAt),
    updatedAt: formatTimestamp(visit.updatedAt),
    deletedAt: visit.deletedAt == null ? null : formatTimestamp(visit.deletedAt!),
  );

  Map<String, dynamic> toJson() => _$VisitDtoToJson(this);

  Visit toDomain() => Visit(
    id: id,
    clientId: clientId,
    doneAt: parseDate(doneAt),
    priceGrosze: priceGrosze,
    note: note,
    appointmentId: appointmentId,
    createdAt: parseTimestamp(createdAt),
    updatedAt: parseTimestamp(updatedAt),
    deletedAt: deletedAt == null ? null : parseTimestamp(deletedAt!),
  );
}
