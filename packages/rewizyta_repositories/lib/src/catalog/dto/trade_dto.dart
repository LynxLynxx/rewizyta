import 'package:json_annotation/json_annotation.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';

part 'trade_dto.g.dart';

/// Wire shape of a `trades` row for `sync_push` / `sync_pull`.
@JsonSerializable()
final class const TradeDto({
  required final String id,
  required final String name,
  required final int sortOrder,
  required final bool isArchived,
  required final String createdAt,
  required final String updatedAt,
  final String? userId,
  final String? templateKey,
  final String? deletedAt,
}) {
  factory fromJson(Map<String, dynamic> json) => _$TradeDtoFromJson(json);

  factory fromDomain(Trade trade, {String? userId}) => TradeDto(
    id: trade.id,
    userId: userId,
    name: trade.name,
    templateKey: trade.templateKey,
    sortOrder: trade.sortOrder,
    isArchived: trade.isArchived,
    createdAt: formatTimestamp(trade.createdAt),
    updatedAt: formatTimestamp(trade.updatedAt),
    deletedAt: trade.deletedAt == null ? null : formatTimestamp(trade.deletedAt!),
  );

  Map<String, dynamic> toJson() => _$TradeDtoToJson(this);

  Trade toDomain() => Trade(
    id: id,
    name: name,
    templateKey: templateKey,
    sortOrder: sortOrder,
    isArchived: isArchived,
    createdAt: parseTimestamp(createdAt),
    updatedAt: parseTimestamp(updatedAt),
    deletedAt: deletedAt == null ? null : parseTimestamp(deletedAt!),
  );
}
