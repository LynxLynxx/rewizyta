import 'package:rewizyta_models/rewizyta_models.dart';

/// SMS reminders: the manual ones the app writes and the ones the server
/// created, pulled for the message history.
abstract interface class RemindersRepository() {
  /// The client's live reminders, latest first.
  Stream<List<Reminder>> watchByClient(String clientId);

  /// Any reminder by id, soft-deleted included.
  Future<Reminder?> find(String id);

  /// Upserts the row and queues it for the push in one transaction.
  Future<void> upsert(Reminder reminder);
}
