import 'package:json_annotation/json_annotation.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/converters.dart';

part 'device_dto.g.dart';

/// Wire shape of a `devices` row for `sync_push` / `sync_pull`.
@JsonSerializable()
final class const DeviceDto({
  required final String id,
  required final String platform,
  required final String createdAt,
  required final String updatedAt,
  final String? userId,
  final String? pushToken,
  final String? pushProvider,
  final String? appVersion,
  final String? lastSeenAt,
  final String? deletedAt,
}) {
  factory fromJson(Map<String, dynamic> json) => _$DeviceDtoFromJson(json);

  factory fromDomain(Device device, {String? userId}) => DeviceDto(
    id: device.id,
    userId: userId,
    platform: enumToSql(device.platform),
    pushToken: device.pushToken,
    pushProvider: device.pushProvider == null ? null : enumToSql(device.pushProvider!),
    appVersion: device.appVersion,
    lastSeenAt: device.lastSeenAt == null ? null : formatTimestamp(device.lastSeenAt!),
    createdAt: formatTimestamp(device.createdAt),
    updatedAt: formatTimestamp(device.updatedAt),
    deletedAt: device.deletedAt == null ? null : formatTimestamp(device.deletedAt!),
  );

  Map<String, dynamic> toJson() => _$DeviceDtoToJson(this);

  Device toDomain() => Device(
    id: id,
    platform: const EnumConverter(DevicePlatform.values).fromSql(platform),
    pushToken: pushToken,
    pushProvider: pushProvider == null
        ? null
        : const EnumConverter(PushProvider.values).fromSql(pushProvider!),
    appVersion: appVersion,
    lastSeenAt: lastSeenAt == null ? null : parseTimestamp(lastSeenAt!),
    createdAt: parseTimestamp(createdAt),
    updatedAt: parseTimestamp(updatedAt),
    deletedAt: deletedAt == null ? null : parseTimestamp(deletedAt!),
  );
}
