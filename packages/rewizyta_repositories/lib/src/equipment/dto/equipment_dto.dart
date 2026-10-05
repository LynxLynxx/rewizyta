import 'package:json_annotation/json_annotation.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';

part 'equipment_dto.g.dart';

/// Wire shape of an `equipment` row for `sync_push` / `sync_pull`. The due
/// dates travel with it: the server trusts the phone's cache.
@JsonSerializable()
final class const EquipmentDto({
  required final String id,
  required final String clientId,
  required final String serviceTypeId,
  required final int count,
  required final String createdAt,
  required final String updatedAt,
  final String? userId,
  final String? label,
  final String? note,
  final String? lastVisitAt,
  final String? nextDueAt,
  final String? deletedAt,
}) {
  factory fromJson(Map<String, dynamic> json) => _$EquipmentDtoFromJson(json);

  factory fromDomain(Equipment equipment, {String? userId}) => EquipmentDto(
    id: equipment.id,
    userId: userId,
    clientId: equipment.clientId,
    serviceTypeId: equipment.serviceTypeId,
    label: equipment.label,
    count: equipment.count,
    note: equipment.note,
    lastVisitAt: equipment.lastVisitAt == null ? null : formatDate(equipment.lastVisitAt!),
    nextDueAt: equipment.nextDueAt == null ? null : formatDate(equipment.nextDueAt!),
    createdAt: formatTimestamp(equipment.createdAt),
    updatedAt: formatTimestamp(equipment.updatedAt),
    deletedAt: equipment.deletedAt == null ? null : formatTimestamp(equipment.deletedAt!),
  );

  Map<String, dynamic> toJson() => _$EquipmentDtoToJson(this);

  Equipment toDomain() => Equipment(
    id: id,
    clientId: clientId,
    serviceTypeId: serviceTypeId,
    label: label,
    count: count,
    note: note,
    lastVisitAt: lastVisitAt == null ? null : parseDate(lastVisitAt!),
    nextDueAt: nextDueAt == null ? null : parseDate(nextDueAt!),
    createdAt: parseTimestamp(createdAt),
    updatedAt: parseTimestamp(updatedAt),
    deletedAt: deletedAt == null ? null : parseTimestamp(deletedAt!),
  );
}
