import 'package:rewizyta_models/rewizyta_models.dart';

/// Booked visits, with the outbox rows for them.
abstract interface class AppointmentsRepository() {
  /// Live appointments starting in [from, to), earliest first: the day and
  /// week views.
  Stream<List<Appointment>> watchBetween(DateTime from, DateTime to);

  /// The client's live appointments, latest first.
  Stream<List<Appointment>> watchByClient(String clientId);

  /// Any appointment by id, soft-deleted included.
  Future<Appointment?> find(String id);

  /// Upserts the row and queues it for the push in one transaction.
  Future<void> upsert(Appointment appointment);
}
