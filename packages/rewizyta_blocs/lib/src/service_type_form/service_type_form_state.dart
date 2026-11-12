import 'package:equatable/equatable.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// The service type sheet. [name], [cycle] and [price] hold what the user
/// typed; the getters read them with the service's rules, so a save the
/// service would reject is never offered.
final class const ServiceTypeFormState({
  final bool isEditing = false,
  final bool isSaving = false,

  /// The default the edited row was copied from; its localized name is the
  /// hint while [name] is empty.
  final ServiceTypeTemplate? template,
  final String name = '',
  final String cycle = '',
  final String price = '',
  final bool isArchived = false,
}) with Equatable {
  /// Whole months from 1 to [ServiceType.maxCycleMonths], or null.
  int? get cycleMonths => switch (int.tryParse(cycle.trim())) {
    final months? when months >= 1 && months <= ServiceType.maxCycleMonths => months,
    _ => null,
  };

  bool get isCycleInvalid => cycleMonths == null;

  /// Empty or an amount, as on the visit sheet.
  bool get isPriceInvalid => price.trim().isNotEmpty && parseMoney(price) == null;

  /// A default may go blank (its own name comes back); a type of the user's
  /// own may not.
  bool get isNameMissing => template == null && name.trim().isEmpty;

  bool get canSave => !isSaving && !isNameMissing && !isCycleInvalid && !isPriceInvalid;

  ServiceTypeFormState copyWith({
    bool? isEditing,
    bool? isSaving,
    ServiceTypeTemplate? template,
    String? name,
    String? cycle,
    String? price,
    bool? isArchived,
  }) {
    return ServiceTypeFormState(
      isEditing: isEditing ?? this.isEditing,
      isSaving: isSaving ?? this.isSaving,
      template: template ?? this.template,
      name: name ?? this.name,
      cycle: cycle ?? this.cycle,
      price: price ?? this.price,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  List<Object?> get props => [isEditing, isSaving, template, name, cycle, price, isArchived];
}

enum ServiceTypeFormSignal() {
  /// The service type was written; the sheet closes.
  saved,
}
