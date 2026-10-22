import 'package:equatable/equatable.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';

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

  /// The service's verdict on the last save; cleared by the next edit.
  final ClientValidationError? error,
}) with Equatable {
  static final _nonDigits = RegExp(r'\D');

  /// The prototype's rule: a name of 2+ characters and a phone of 9+ digits.
  bool get canSave =>
      !isLoading &&
      !isSaving &&
      name.trim().length >= 2 &&
      phone.replaceAll(_nonDigits, '').length >= 9;

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
    error,
  ];
}

/// The client was written; [created] tells a new client from an edit.
final class const ClientFormSaved({required final String id, required final bool created})
    with Equatable {
  @override
  List<Object?> get props => [id, created];
}
