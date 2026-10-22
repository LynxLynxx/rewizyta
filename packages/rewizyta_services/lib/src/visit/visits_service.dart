import 'package:rewizyta_models/rewizyta_models.dart';

/// Visits and what they serviced. Every write recomputes the due dates of the
/// equipment it touches in the same transaction.
abstract interface class VisitsService() {
  /// Records a visit (no [id]) or updates one: the visit, one item per
  /// equipment in [equipmentIds] (the work done; an unticked item is
  /// soft-deleted, a re-ticked one restored) and the due dates of every
  /// equipment it adds, keeps or removes. [doneAt] is cut to its calendar day.
  /// Throws [VisitNotFoundException] for an unknown [id] and
  /// [VisitValidationException] when [priceGrosze] is negative.
  Future<Visit> saveVisit({
    String? id,
    required String clientId,
    required DateTime doneAt,
    required Set<String> equipmentIds,
    int? priceGrosze,
    String? note,
    String? appointmentId,
  });

  /// Soft-deletes the visit and recomputes the due dates of what it serviced.
  /// Throws [VisitNotFoundException] for an unknown [id].
  Future<void> deleteVisit(String id);
}
