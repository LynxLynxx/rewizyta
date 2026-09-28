import 'package:json_annotation/json_annotation.dart';
import 'package:rewizyta_models/rewizyta_models.dart';

part 'client_dto.g.dart';

/// Wire shape of a `clients` row for `sync_push` / `sync_pull`. Field names
/// are the Postgres column names (build.yaml: field_rename snake).
@JsonSerializable()
final class const ClientDto({
  required final String id,
  required final String name,
  required final String createdAt,
  required final String updatedAt,
  final String? userId,
  final String? phone,
  final String? address,
  final String? town,
  final String? note,
  final String? deletedAt,
}) {
  factory fromJson(Map<String, dynamic> json) => _$ClientDtoFromJson(json);

  factory fromDomain(Client client, {String? userId}) => ClientDto(
    id: client.id,
    userId: userId,
    name: client.name,
    phone: client.phone,
    address: client.address,
    town: client.town,
    note: client.note,
    createdAt: client.createdAt.toUtc().toIso8601String(),
    updatedAt: client.updatedAt.toUtc().toIso8601String(),
    deletedAt: client.deletedAt?.toUtc().toIso8601String(),
  );

  Map<String, dynamic> toJson() => _$ClientDtoToJson(this);

  Client toDomain() => Client(
    id: id,
    name: name,
    phone: phone,
    address: address,
    town: town,
    note: note,
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
    deletedAt: deletedAt == null ? null : DateTime.parse(deletedAt!),
  );
}
