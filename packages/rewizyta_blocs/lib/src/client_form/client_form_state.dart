import 'package:equatable/equatable.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// The add/edit form. Fields hold what the user typed; the service trims,
/// parses the phone and validates on save.
final class const ClientFormState({
  final bool isEditing = false,
  final bool isLoading = false,
  final bool isSaving = false,
  final String name = '',
  final String phone = '',
  final String addressLine = '',
  final String postalCode = '',
  final String town = '',
  final String note = '',
  final List<ServiceTypeViewModel> serviceTypes = const [],
  final List<ClientFormEquipmentRow> equipment = const [],

  /// The service's verdict on the last save; cleared by the next edit.
  final ClientValidationError? error,
}) with Equatable {
  static final _nonDigits = RegExp(r'\D');

  /// The prototype's rule: a name of 2+ characters and a phone of 9+ digits.
  /// A last visit that is not a date also blocks it, so that nothing typed is
  /// silently dropped.
  bool get canSave =>
      !isLoading &&
      !isSaving &&
      name.trim().length >= 2 &&
      phone.replaceAll(_nonDigits, '').length >= 9 &&
      equipment.every((row) => row.lastVisitError == null);

  /// A new row needs a service type that is not archived.
  bool get canAddEquipment => serviceTypes.any((type) => !type.isArchived);

  /// The chips of [row]: an archived type is hidden from pickers, unless the
  /// row already points at it.
  List<ServiceTypeViewModel> serviceTypesFor(ClientFormEquipmentRow row) => [
    for (final type in serviceTypes)
      if (!type.isArchived || type.id == row.serviceTypeId) type,
  ];

  ClientFormState copyWith({
    bool? isEditing,
    bool? isLoading,
    bool? isSaving,
    String? name,
    String? phone,
    String? addressLine,
    String? postalCode,
    String? town,
    String? note,
    List<ServiceTypeViewModel>? serviceTypes,
    List<ClientFormEquipmentRow>? equipment,
    Optional<ClientValidationError>? error,
  }) {
    return ClientFormState(
      isEditing: isEditing ?? this.isEditing,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      addressLine: addressLine ?? this.addressLine,
      postalCode: postalCode ?? this.postalCode,
      town: town ?? this.town,
      note: note ?? this.note,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      equipment: equipment ?? this.equipment,
      error: error.dataOr(this.error),
    );
  }

  @override
  List<Object?> get props => [
    isEditing,
    isLoading,
    isSaving,
    name,
    phone,
    addressLine,
    postalCode,
    town,
    note,
    serviceTypes,
    equipment,
    error,
  ];
}

/// One equipment row of the form. [lastVisit] holds what the user typed; the
/// last three fields are derived from it by the cubit on every change.
final class const ClientFormEquipmentRow({
  required final int rowKey,
  required final String serviceTypeId,

  /// The saved equipment this row edits; null for a new row.
  final String? id,
  final String label = '',
  final String lastVisit = '',

  /// A saved last visit is read-only here: a form date could only add a
  /// visit, and an earlier one would not move the date at all.
  final bool isLastVisitLocked = false,
  final LastVisitError? lastVisitError,
  final String? nextDueLabel,
  final DueStatusViewModel? status,
}) with Equatable {
  @override
  List<Object?> get props => [
    rowKey,
    serviceTypeId,
    id,
    label,
    lastVisit,
    isLastVisitLocked,
    lastVisitError,
    nextDueLabel,
    status,
  ];
}

/// The client was written; [created] tells a new client from an edit.
final class const ClientFormSaved({required final String id, required final bool created})
    with Equatable {
  @override
  List<Object?> get props => [id, created];
}
