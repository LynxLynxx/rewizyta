import 'package:json_annotation/json_annotation.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';

part 'service_type_dto.g.dart';

/// Wire shape of a `service_types` row for `sync_push` / `sync_pull`.
@JsonSerializable()
final class const ServiceTypeDto({
  required final String id,
  required final String name,
  required final int cycleMonths,
  required final int sortOrder,
  required final bool isArchived,
  required final String createdAt,
  required final String updatedAt,
  final String? userId,
  final String? tradeId,
  final int? defaultPriceGrosze,
  final String? templateKey,
  final String? deletedAt,
}) {
  factory fromJson(Map<String, dynamic> json) => _$ServiceTypeDtoFromJson(json);

  factory fromDomain(ServiceType type, {String? userId}) => ServiceTypeDto(
    id: type.id,
    userId: userId,
    tradeId: type.tradeId,
    name: type.name,
    cycleMonths: type.cycleMonths,
    defaultPriceGrosze: type.defaultPriceGrosze,
    templateKey: type.templateKey,
    sortOrder: type.sortOrder,
    isArchived: type.isArchived,
    createdAt: formatTimestamp(type.createdAt),
    updatedAt: formatTimestamp(type.updatedAt),
    deletedAt: type.deletedAt == null ? null : formatTimestamp(type.deletedAt!),
  );

  Map<String, dynamic> toJson() => _$ServiceTypeDtoToJson(this);

  ServiceType toDomain() => ServiceType(
    id: id,
    tradeId: tradeId,
    name: name,
    cycleMonths: cycleMonths,
    defaultPriceGrosze: defaultPriceGrosze,
    templateKey: templateKey,
    sortOrder: sortOrder,
    isArchived: isArchived,
    createdAt: parseTimestamp(createdAt),
    updatedAt: parseTimestamp(updatedAt),
    deletedAt: deletedAt == null ? null : parseTimestamp(deletedAt!),
  );
}
