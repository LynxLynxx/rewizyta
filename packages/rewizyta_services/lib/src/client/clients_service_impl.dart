import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:rewizyta_services/src/client/clients_service.dart';
import 'package:rewizyta_services/src/common/clean_text.dart';
import 'package:rewizyta_services/src/equipment/equipment_service.dart';
import 'package:rewizyta_services/src/visit/visits_service.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:uuid/uuid.dart';

final class ClientsServiceImpl(
  final ClientsRepository _repository,
  final EquipmentService _equipment,
  final VisitsService _visits,
  final TransactionRunner _transaction, {
  DateTime Function()? now,
  Uuid? uuid,
}) implements ClientsService {
  static final _e164 = RegExp(r'^\+[1-9]\d{6,14}$');
  static final _separators = RegExp(r'[\s\-().]');
  static final _nationalNumber = RegExp(r'^\d{9}$');

  final DateTime Function() _now = now ?? DateTime.timestamp;
  final Uuid _uuid = uuid ?? const Uuid();

  @override
  Stream<List<Client>> watchClients() => _repository.watchAll().map(
    (clients) => [...clients]..sort((a, b) => comparePolish(a.name, b.name)),
  );

  @override
  Stream<Client> watchClient(String id) =>
      _repository.watch(id).map((client) => client ?? (throw ClientNotFoundException(id)));

  @override
  Future<Client> getClient(String id) async {
    final client = await _repository.find(id);
    if (client == null) {
      throw ClientNotFoundException(id);
    }
    return client;
  }

  @override
  Future<Client> saveClient({
    String? id,
    required String name,
    String? phone,
    String? addressLine,
    String? town,
    String? postalCode,
    String? note,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const ClientValidationException(ClientValidationError.nameEmpty);
    }
    final cleanPhone = _toE164(phone);
    if (cleanPhone != null && !_e164.hasMatch(cleanPhone)) {
      throw const ClientValidationException(ClientValidationError.phoneInvalid);
    }

    final now = _now();
    final existing = id == null ? null : await getClient(id);
    final cleanAddressLine = cleanText(addressLine);
    final cleanTown = cleanText(town);
    final cleanPostalCode = cleanText(postalCode);
    final keepsCoordinates =
        existing != null &&
        cleanText(existing.addressLine) == cleanAddressLine &&
        cleanText(existing.town) == cleanTown &&
        cleanText(existing.postalCode) == cleanPostalCode;
    final client = Client(
      id: existing?.id ?? _uuid.v4(),
      name: trimmedName,
      phone: cleanPhone,
      addressLine: cleanAddressLine,
      town: cleanTown,
      postalCode: cleanPostalCode,
      lat: keepsCoordinates ? existing.lat : null,
      lng: keepsCoordinates ? existing.lng : null,
      note: cleanText(note),
      contactId: existing?.contactId,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _repository.upsert(client);
    return client;
  }

  @override
  Future<Client> saveClientWithEquipment({
    String? id,
    required String name,
    String? phone,
    String? addressLine,
    String? town,
    String? postalCode,
    String? note,
    required List<EquipmentDraft> equipment,
  }) {
    return _transaction.run(() async {
      final client = await saveClient(
        id: id,
        name: name,
        phone: phone,
        addressLine: addressLine,
        town: town,
        postalCode: postalCode,
        note: note,
      );
      final current = {for (final e in await _equipment.findByClient(client.id)) e.id: e};
      final keptIds = {for (final draft in equipment) draft.id};
      for (final removedId in current.keys.where((id) => !keptIds.contains(id))) {
        await _equipment.deleteEquipment(removedId);
      }
      final servicedByDay = <DateTime, Set<String>>{};
      for (final draft in equipment) {
        final saved = await _saveDraft(draft, client.id, current[draft.id]);
        if (draft.lastVisitAt case final day?) {
          (servicedByDay[day] ??= {}).add(saved.id);
        }
      }
      for (final MapEntry(key: day, value: equipmentIds) in servicedByDay.entries) {
        await _visits.saveVisit(clientId: client.id, doneAt: day, equipmentIds: equipmentIds);
      }
      return client;
    });
  }

  @override
  Future<void> deleteClient(String id) async {
    final client = await getClient(id);
    final now = _now();
    await _repository.upsert(client.copyWith(updatedAt: now, deletedAt: Optional(now)));
  }

  @override
  Future<void> restoreClient(String id) async {
    final client = await getClient(id);
    await _repository.upsert(
      client.copyWith(updatedAt: _now(), deletedAt: const Optional.empty()),
    );
  }

  /// An untouched row is not written, so it queues no push. The form does not
  /// edit [Equipment.count] and [Equipment.note], so they stay as they are.
  Future<Equipment> _saveDraft(EquipmentDraft draft, String clientId, Equipment? existing) async {
    final label = cleanText(draft.label);
    if (existing != null &&
        existing.serviceTypeId == draft.serviceTypeId &&
        existing.label == label) {
      return existing;
    }
    return await _equipment.saveEquipment(
      id: draft.id,
      clientId: clientId,
      serviceTypeId: draft.serviceTypeId,
      label: label,
      count: existing?.count ?? 1,
      note: existing?.note,
    );
  }

  /// Drops separators and reads a bare nine-digit number as Polish. Anything
  /// else is returned as typed, for the E.164 check to reject.
  static String? _toE164(String? phone) {
    final compact = cleanText(phone)?.replaceAll(_separators, '');
    if (compact == null || compact.isEmpty) return null;
    if (compact.startsWith('00')) return '+${compact.substring(2)}';
    if (_nationalNumber.hasMatch(compact)) return '+48$compact';
    return compact;
  }
}
