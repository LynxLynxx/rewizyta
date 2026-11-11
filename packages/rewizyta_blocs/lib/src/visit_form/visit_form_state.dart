import 'package:equatable/equatable.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// The "Zapisz wizytę" sheet. [date], [price] and [note] hold what the user
/// typed; [dateError], [isPriceInvalid] and [nextDueLabel] are derived from
/// them by the cubit on every change, so [copyWith] keeps them as they are.
final class const VisitFormState({
  final bool isLoading = true,
  final bool isSaving = false,

  /// An existing visit from the history, which the sheet can also delete.
  final bool isEditing = false,

  /// The client's equipment, each a chip.
  final List<ClientEquipmentViewModel> equipment = const [],

  /// The ids of the chips that are on: the work done.
  final Set<String> ticked = const {},
  final String date = '',
  final String price = '',
  final String note = '',
  final LastVisitError? dateError,
  final bool isPriceInvalid = false,

  /// The earliest next due date of the ticked equipment after this visit.
  final String? nextDueLabel,
}) with Equatable {
  /// A readable date that is not in the future, a price that is empty or an
  /// amount, and some work done when the client has equipment.
  bool get canSave =>
      !isLoading &&
      !isSaving &&
      date.trim().isNotEmpty &&
      dateError == null &&
      !isPriceInvalid &&
      (equipment.isEmpty || ticked.isNotEmpty);

  VisitFormState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isEditing,
    List<ClientEquipmentViewModel>? equipment,
    Set<String>? ticked,
    String? date,
    String? price,
    String? note,
  }) {
    return VisitFormState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isEditing: isEditing ?? this.isEditing,
      equipment: equipment ?? this.equipment,
      ticked: ticked ?? this.ticked,
      date: date ?? this.date,
      price: price ?? this.price,
      note: note ?? this.note,
      dateError: dateError,
      isPriceInvalid: isPriceInvalid,
      nextDueLabel: nextDueLabel,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSaving,
    isEditing,
    equipment,
    ticked,
    date,
    price,
    note,
    dateError,
    isPriceInvalid,
    nextDueLabel,
  ];
}

enum VisitFormSignal() {
  /// The visit was written; the sheet closes.
  saved,

  /// The visit was soft-deleted; the sheet closes and the card offers an undo.
  deleted,
}
