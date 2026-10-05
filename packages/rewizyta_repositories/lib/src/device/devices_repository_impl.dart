import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';
import 'package:rewizyta_repositories/src/database/outbox_writer.dart';
import 'package:rewizyta_repositories/src/device/device_row_mapping.dart';
import 'package:rewizyta_repositories/src/device/devices_repository.dart';
import 'package:rewizyta_repositories/src/device/dto/device_dto.dart';

final class const DevicesRepositoryImpl(final AppDatabase _db) implements DevicesRepository {
  @override
  Future<Device?> find(String id) async {
    final row = await (_db.select(_db.devices)..where((d) => d.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> upsert(Device device) => _db.upsertSynced(
    _db.devices,
    device.toCompanion(),
    id: device.id,
    isDeleted: device.isDeleted,
    payload: DeviceDto.fromDomain(device).toJson(),
  );
}
