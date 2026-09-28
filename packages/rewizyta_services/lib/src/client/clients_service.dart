import 'package:rewizyta_models/rewizyta_models.dart';

/// Client bookkeeping. Validates, stamps timestamps and ids, and delegates
/// persistence to the repository.
abstract interface class ClientsService() {
  Stream<List<Client>> watchClients();

  Future<Client> getClient(String id);

  /// Creates (no [id]) or updates a client. Throws
  /// [ClientValidationException] when the name is empty or the phone is not
  /// E.164.
  Future<Client> saveClient({
    String? id,
    required String name,
    String? phone,
    String? address,
    String? town,
    String? note,
  });

  Future<void> deleteClient(String id);
}
