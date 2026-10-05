import 'package:drift/drift.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/src/catalog/dto/service_type_dto.dart';
import 'package:rewizyta_repositories/src/catalog/service_type_row_mapping.dart';
import 'package:rewizyta_repositories/src/catalog/service_types_repository.dart';
import 'package:rewizyta_repositories/src/database/app_database.dart';
import 'package:rewizyta_repositories/src/database/outbox_writer.dart';

final class const ServiceTypesRepositoryImpl(final AppDatabase _db)
    implements ServiceTypesRepository {
  @override
  Stream<List<ServiceType>> watchAll() {
    final query = _db.select(_db.serviceTypes)
      ..where((s) => s.deletedAt.isNull())
      ..orderBy([(s) => OrderingTerm.asc(s.sortOrder), (s) => OrderingTerm.asc(s.name)]);
    return query.watch().map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  @override
  Future<ServiceType?> find(String id) async {
    final query = _db.select(_db.serviceTypes)..where((s) => s.id.equals(id));
    final row = await query.getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<ServiceType?> findByTemplateKey(String templateKey) async {
    final query = _db.select(_db.serviceTypes)..where((s) => s.templateKey.equals(templateKey));
    final row = await query.getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> upsert(ServiceType serviceType) => _db.upsertSynced(
    _db.serviceTypes,
    serviceType.toCompanion(),
    id: serviceType.id,
    isDeleted: serviceType.isDeleted,
    payload: ServiceTypeDto.fromDomain(serviceType).toJson(),
  );
}
