import 'package:rewizyta_models/rewizyta_models.dart';

/// Client bookkeeping. Validates, stamps timestamps and ids, and delegates
/// persistence to the repository.
abstract interface class ClientsService() {
  /// Live, non-deleted clients in Polish alphabetical order.
  Stream<List<Client>> watchClients();

  /// One client as it changes. Emits [ClientNotFoundException] as an error
  /// while the id is unknown.
  Stream<Client> watchClient(String id);

  Future<Client> getClient(String id);

  /// Creates (no [id]) or updates a client. The phone is typed the way people
  /// write it (`601 234 567`, `0048 601…`, `+48 601…`) and stored as E.164.
  /// Throws [ClientValidationException] when the name is empty or the phone
  /// is not a number. An update keeps the contact link, and the coordinates
  /// while the address stays the same (a new address has to be geocoded
  /// again).
  Future<Client> saveClient({
    String? id,
    required String name,
    String? phone,
    String? addressLine,
    String? town,
    String? postalCode,
    String? note,
  });

  /// [saveClient] and the client's equipment in one transaction, as the form
  /// shows them: a draft with an id updates that row, one without adds a row,
  /// and live equipment missing from [equipment] is soft-deleted. Drafts with
  /// a [EquipmentDraft.lastVisitAt] are recorded as visits, one per day, so
  /// the due dates stay derived.
  Future<Client> saveClientWithEquipment({
    String? id,
    required String name,
    String? phone,
    String? addressLine,
    String? town,
    String? postalCode,
    String? note,
    required List<EquipmentDraft> equipment,
  });

  Future<void> deleteClient(String id);

  /// Undoes [deleteClient].
  Future<void> restoreClient(String id);
}
