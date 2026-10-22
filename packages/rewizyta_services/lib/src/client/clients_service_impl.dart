import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:rewizyta_services/src/client/clients_service.dart';
import 'package:rewizyta_services/src/common/clean_text.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:uuid/uuid.dart';

final class ClientsServiceImpl(
  final ClientsRepository _repository, {
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
