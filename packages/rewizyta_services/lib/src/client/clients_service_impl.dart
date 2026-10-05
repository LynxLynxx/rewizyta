import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:rewizyta_services/src/client/clients_service.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:uuid/uuid.dart';

final class ClientsServiceImpl(
  final ClientsRepository _repository, {
  DateTime Function()? now,
  Uuid? uuid,
}) implements ClientsService {
  static final _e164 = RegExp(r'^\+[1-9]\d{6,14}$');

  final DateTime Function() _now = now ?? DateTime.timestamp;
  final Uuid _uuid = uuid ?? const Uuid();

  @override
  Stream<List<Client>> watchClients() => _repository.watchAll();

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
    final cleanPhone = _clean(phone);
    if (cleanPhone != null && !_e164.hasMatch(cleanPhone)) {
      throw const ClientValidationException(ClientValidationError.phoneInvalid);
    }

    final now = _now();
    final existing = id == null ? null : await getClient(id);
    final cleanAddressLine = _clean(addressLine);
    final cleanTown = _clean(town);
    final cleanPostalCode = _clean(postalCode);
    final keepsCoordinates =
        existing != null &&
        _clean(existing.addressLine) == cleanAddressLine &&
        _clean(existing.town) == cleanTown &&
        _clean(existing.postalCode) == cleanPostalCode;
    final client = Client(
      id: existing?.id ?? _uuid.v4(),
      name: trimmedName,
      phone: cleanPhone,
      addressLine: cleanAddressLine,
      town: cleanTown,
      postalCode: cleanPostalCode,
      lat: keepsCoordinates ? existing.lat : null,
      lng: keepsCoordinates ? existing.lng : null,
      note: _clean(note),
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

  /// Trimmed, or null when nothing is left, so an empty form field and a
  /// missing value are stored the same way.
  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
