import 'package:json_annotation/json_annotation.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';

part 'visit_item_dto.g.dart';

/// Wire shape of a `visit_items` row for `sync_push` / `sync_pull`.
@JsonSerializable()
final class const VisitItemDto({
  required final String id,
  required final String visitId,
  required final String equipmentId,
  required final String createdAt,
  required final String updatedAt,
  final String? userId,
  final String? deletedAt,
}) {
  factory fromJson(Map<String, dynamic> json) => _$VisitItemDtoFromJson(json);

  factory fromDomain(VisitItem item, {String? userId}) => VisitItemDto(
    id: item.id,
    userId: userId,
    visitId: item.visitId,
    equipmentId: item.equipmentId,
    createdAt: formatTimestamp(item.createdAt),
    updatedAt: formatTimestamp(item.updatedAt),
    deletedAt: item.deletedAt == null ? null : formatTimestamp(item.deletedAt!),
  );

  Map<String, dynamic> toJson() => _$VisitItemDtoToJson(this);

  VisitItem toDomain() => VisitItem(
    id: id,
    visitId: visitId,
    equipmentId: equipmentId,
    createdAt: parseTimestamp(createdAt),
    updatedAt: parseTimestamp(updatedAt),
    deletedAt: deletedAt == null ? null : parseTimestamp(deletedAt!),
  );
}
