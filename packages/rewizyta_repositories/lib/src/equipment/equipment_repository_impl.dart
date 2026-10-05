import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';
import 'package:rewizyta_repositories/src/database/outbox_writer.dart';
import 'package:rewizyta_repositories/src/equipment/dto/equipment_dto.dart';
import 'package:rewizyta_repositories/src/equipment/equipment_repository.dart';
import 'package:rewizyta_repositories/src/equipment/equipment_row_mapping.dart';

final class const EquipmentRepositoryImpl(final AppDatabase _db) implements EquipmentRepository {
  @override
  Stream<List<Equipment>> watchByClient(String clientId) {
    final query = _db.select(_db.equipmentTable)
      ..where((e) => e.clientId.equals(clientId) & e.deletedAt.isNull())
      ..orderBy([(e) => OrderingTerm.asc(e.createdAt), (e) => OrderingTerm.asc(e.id)]);
    return query.watch().map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  @override
  Future<Equipment?> find(String id) async {
    final query = _db.select(_db.equipmentTable)..where((e) => e.id.equals(id));
    final row = await query.getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<List<Equipment>> findByServiceType(String serviceTypeId) async {
    final query = _db.select(_db.equipmentTable)
      ..where((e) => e.serviceTypeId.equals(serviceTypeId) & e.deletedAt.isNull());
    final rows = await query.get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<void> upsert(Equipment equipment) => _db.upsertSynced(
    _db.equipmentTable,
    equipment.toCompanion(),
    id: equipment.id,
    isDeleted: equipment.isDeleted,
    payload: EquipmentDto.fromDomain(equipment).toJson(),
  );
}
