import 'package:json_annotation/json_annotation.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';

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
  final String? addressLine,
  final String? town,
  final String? postalCode,
  final double? lat,
  final double? lng,
  final String? note,
  final String? contactId,
  final String? deletedAt,
}) {
  factory fromJson(Map<String, dynamic> json) => _$ClientDtoFromJson(json);

  factory fromDomain(Client client, {String? userId}) => ClientDto(
    id: client.id,
    userId: userId,
    name: client.name,
    phone: client.phone,
    addressLine: client.addressLine,
    town: client.town,
    postalCode: client.postalCode,
    lat: client.lat,
    lng: client.lng,
    note: client.note,
    contactId: client.contactId,
    createdAt: formatTimestamp(client.createdAt),
    updatedAt: formatTimestamp(client.updatedAt),
    deletedAt: client.deletedAt == null ? null : formatTimestamp(client.deletedAt!),
  );

  Map<String, dynamic> toJson() => _$ClientDtoToJson(this);

  Client toDomain() => Client(
    id: id,
    name: name,
    phone: phone,
    addressLine: addressLine,
    town: town,
    postalCode: postalCode,
    lat: lat,
    lng: lng,
    note: note,
    contactId: contactId,
    createdAt: parseTimestamp(createdAt),
    updatedAt: parseTimestamp(updatedAt),
    deletedAt: deletedAt == null ? null : parseTimestamp(deletedAt!),
  );
}
