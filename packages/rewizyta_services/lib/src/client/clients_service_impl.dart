import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_repositories/rewizyta_repositories.dart';
import 'package:rewizyta_services/src/client/clients_service.dart';
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
    String? address,
    String? town,
    String? note,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const ClientValidationException(ClientValidationError.nameEmpty);
    }
    final trimmedPhone = phone?.trim();
    if (trimmedPhone != null && trimmedPhone.isNotEmpty && !_e164.hasMatch(trimmedPhone)) {
      throw const ClientValidationException(ClientValidationError.phoneInvalid);
    }

    final now = _now();
    final existing = id == null ? null : await getClient(id);
    final client = Client(
      id: existing?.id ?? _uuid.v4(),
      name: trimmedName,
      phone: trimmedPhone == null || trimmedPhone.isEmpty ? null : trimmedPhone,
      address: address?.trim(),
      town: town?.trim(),
      note: note?.trim(),
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
    await _repository.upsert(client.copyWith(updatedAt: now, deletedAt: now));
  }
}
