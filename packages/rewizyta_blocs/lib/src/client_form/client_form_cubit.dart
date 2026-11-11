import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rewizyta_blocs/src/client_form/client_form_state.dart';
import 'package:rewizyta_blocs/src/common/bloc_error_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/common/bloc_signal_emitter_mixin.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// Add (`init(null)`) or edit (`init(id)`) a client and its equipment.
class ClientFormCubit(
  final ClientsService _clientsService,
  final EquipmentService _equipmentService,
  final CatalogService _catalogService, {
  DateTime Function()? now,
}) extends Cubit<ClientFormState>
    with
        BlocErrorEmitterMixin<ClientFormState>,
        BlocSignalEmitterMixin<ClientFormSaved, ClientFormState> {
  this : super(const ClientFormState());

  final DateTime Function() _now = now ?? DateTime.now;
  String? _id;
  int _nextRowKey = 0;

  Future<void> init(String? id) async {
    _id = id;
    emit(state.copyWith(isEditing: id != null, isLoading: true));
    try {
      await _catalogService.ensureDefaults();
      final serviceTypes = await _catalogService.watchServiceTypes().first;
      if (isClosed) return;
      emit(
        state.copyWith(serviceTypes: serviceTypes.map(ServiceTypeViewModel.fromDomain).toList()),
      );
      if (id == null) {
        emit(state.copyWith(isLoading: false, equipment: [?_newRow()]));
        return;
      }
      final client = await _clientsService.getClient(id);
      final equipment = await _equipmentService.findByClient(id);
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          name: client.name,
          phone: client.phone == null ? '' : formatPhone(client.phone!),
          addressLine: client.addressLine ?? '',
          postalCode: client.postalCode ?? '',
          town: client.town ?? '',
          note: client.note ?? '',
          equipment: equipment.map(_savedRow).toList(),
        ),
      );
    } on Exception catch (error) {
      if (isClosed) return;
      emitError(LocalizedException.create(error));
    }
  }

  /// Any edit clears the last validation error.
  void update({
    String? name,
    String? phone,
    String? addressLine,
    String? postalCode,
    String? town,
    String? note,
  }) {
    emit(
      state.copyWith(
        name: name,
        phone: phone,
        addressLine: addressLine,
        postalCode: postalCode,
        town: town,
        note: note,
        error: const Optional.empty(),
      ),
    );
  }

  void addEquipment() {
    final row = _newRow();
    if (row != null) emit(state.copyWith(equipment: [...state.equipment, row]));
  }

  void updateEquipment(int rowKey, {String? serviceTypeId, String? label, String? lastVisit}) {
    emit(
      state.copyWith(
        equipment: [
          for (final row in state.equipment)
            if (row.rowKey == rowKey)
              _row(
                rowKey: rowKey,
                id: row.id,
                serviceTypeId: serviceTypeId ?? row.serviceTypeId,
                label: label ?? row.label,
                lastVisit: lastVisit ?? row.lastVisit,
                isLastVisitLocked: row.isLastVisitLocked,
              )
            else
              row,
        ],
      ),
    );
  }

  /// Only leaves the form; a saved row is soft-deleted when the form is saved.
  void removeEquipment(int rowKey) {
    emit(
      state.copyWith(
        equipment: state.equipment.where((row) => row.rowKey != rowKey).toList(),
      ),
    );
  }

  /// The "Cofnij" on the snackbar after [removeEquipment]. The snackbar can
  /// outlive the page.
  void restoreEquipment(ClientFormEquipmentRow row, int index) {
    if (isClosed) return;
    emit(
      state.copyWith(
        equipment: [...state.equipment]..insert(index.clamp(0, state.equipment.length), row),
      ),
    );
  }

  Future<void> save() async {
    if (!state.canSave) return;
    emit(state.copyWith(isSaving: true));
    try {
      final client = await _clientsService.saveClientWithEquipment(
        id: _id,
        name: state.name,
        phone: state.phone,
        addressLine: state.addressLine,
        postalCode: state.postalCode,
        town: state.town,
        note: state.note,
        equipment: [
          for (final row in state.equipment)
            EquipmentDraft(
              id: row.id,
              serviceTypeId: row.serviceTypeId,
              label: row.label,
              lastVisitAt: row.isLastVisitLocked ? null : parseDate(row.lastVisit),
            ),
        ],
      );
      if (isClosed) return;
      emit(state.copyWith(isSaving: false));
      emitSignal(ClientFormSaved(id: client.id, created: _id == null));
    } on ClientValidationException catch (exception) {
      if (isClosed) return;
      emit(state.copyWith(isSaving: false, error: Optional(exception.error)));
    } on Exception catch (error) {
      if (isClosed) return;
      emit(state.copyWith(isSaving: false));
      emitError(LocalizedException.create(error));
    }
  }

  /// A row on the first service type a picker may offer, or null without one.
  ClientFormEquipmentRow? _newRow() {
    final type = state.serviceTypes.where((type) => !type.isArchived).firstOrNull;
    if (type == null) return null;
    return _row(rowKey: _nextRowKey++, serviceTypeId: type.id);
  }

  ClientFormEquipmentRow _savedRow(Equipment equipment) => _row(
    rowKey: _nextRowKey++,
    id: equipment.id,
    serviceTypeId: equipment.serviceTypeId,
    label: equipment.label ?? '',
    lastVisit: equipment.lastVisitAt == null ? '' : formatDate(equipment.lastVisitAt!),
    isLastVisitLocked: equipment.lastVisitAt != null,
  );

  ClientFormEquipmentRow _row({
    required int rowKey,
    required String serviceTypeId,
    String? id,
    String label = '',
    String lastVisit = '',
    bool isLastVisitLocked = false,
  }) {
    final today = calendarDay(_now());
    final error = isLastVisitLocked ? null : LastVisitError.of(lastVisit, today);
    final lastVisitDate = error == null ? parseDate(lastVisit) : null;
    final type = state.serviceTypes.where((type) => type.id == serviceTypeId).firstOrNull;
    final next = lastVisitDate == null || type == null
        ? null
        : nextDue(lastVisitDate, type.cycleMonths);
    return ClientFormEquipmentRow(
      rowKey: rowKey,
      id: id,
      serviceTypeId: serviceTypeId,
      label: label,
      lastVisit: lastVisit,
      isLastVisitLocked: isLastVisitLocked,
      lastVisitError: error,
      nextDueLabel: next == null ? null : formatDate(next),
      status: next == null ? null : DueStatusViewModel.fromDate(next, today),
    );
  }
}
