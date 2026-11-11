import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rewizyta_blocs/src/common/bloc_error_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/common/bloc_signal_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/visit_form/visit_form_state.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// Records a visit at a client: today, every piece of equipment ticked, so
/// the usual visit is one tap. Or edits or deletes one from the history.
/// Saving moves the due dates ([VisitsService.saveVisit]).
class VisitFormCubit(
  final EquipmentService _equipmentService,
  final CatalogService _catalogService,
  final VisitsService _visitsService, {
  DateTime Function()? now,
}) extends Cubit<VisitFormState>
    with
        BlocErrorEmitterMixin<VisitFormState>,
        BlocSignalEmitterMixin<VisitFormSignal, VisitFormState> {
  this : super(const VisitFormState());

  final DateTime Function() _now = now ?? DateTime.now;
  String? _clientId;
  Visit? _visit;
  List<Equipment> _equipment = const [];
  List<ServiceType> _serviceTypes = const [];

  /// A new visit, or with [visitId] the stored one. Its ticked items may name
  /// equipment deleted since; they have no chip and stay as they are.
  Future<void> init(String clientId, {String? visitId}) async {
    _clientId = clientId;
    try {
      final equipment = await _equipmentService.findByClient(clientId);
      final serviceTypes = await _catalogService.watchServiceTypes().first;
      final visit = visitId == null ? null : await _visitsService.getVisit(visitId);
      final items = visitId == null ? null : await _visitsService.findItems(visitId);
      if (isClosed) return;
      _equipment = equipment;
      _serviceTypes = serviceTypes;
      _visit = visit;
      final today = calendarDay(_now());
      final price = visit?.priceGrosze;
      _emitDerived(
        state.copyWith(
          isLoading: false,
          isEditing: visit != null,
          equipment: [
            for (final item in equipment)
              ClientEquipmentViewModel.fromDomain(item, serviceTypes, today),
          ],
          ticked: items == null
              ? {for (final item in equipment) item.id}
              : {for (final item in items) item.equipmentId},
          date: formatDate(visit?.doneAt ?? today),
          price: price == null ? '' : formatMoney(price),
          note: visit?.note ?? '',
        ),
      );
    } on Exception catch (error) {
      if (isClosed) return;
      emitError(LocalizedException.create(error));
    }
  }

  void toggle(String equipmentId) {
    final ticked = {...state.ticked};
    if (!ticked.remove(equipmentId)) ticked.add(equipmentId);
    _emitDerived(state.copyWith(ticked: ticked));
  }

  void update({String? date, String? price, String? note}) {
    _emitDerived(state.copyWith(date: date, price: price, note: note));
  }

  Future<void> save() async {
    final clientId = _clientId;
    if (clientId == null || !state.canSave) return;
    emit(state.copyWith(isSaving: true));
    try {
      await _visitsService.saveVisit(
        id: _visit?.id,
        clientId: clientId,
        doneAt: parseDate(state.date)!,
        equipmentIds: state.ticked,
        priceGrosze: parseMoney(state.price),
        note: state.note,
        appointmentId: _visit?.appointmentId,
      );
      if (isClosed) return;
      emit(state.copyWith(isSaving: false));
      emitSignal(VisitFormSignal.saved);
    } on Exception catch (error) {
      if (isClosed) return;
      emit(state.copyWith(isSaving: false));
      emitError(LocalizedException.create(error));
    }
  }

  Future<void> delete() async {
    final visit = _visit;
    if (visit == null || state.isSaving) return;
    emit(state.copyWith(isSaving: true));
    try {
      await _visitsService.deleteVisit(visit.id);
      if (isClosed) return;
      emit(state.copyWith(isSaving: false));
      emitSignal(VisitFormSignal.deleted);
    } on Exception catch (error) {
      if (isClosed) return;
      emit(state.copyWith(isSaving: false));
      emitError(LocalizedException.create(error));
    }
  }

  /// Emits [next] with the fields derived from what was typed and ticked.
  void _emitDerived(VisitFormState next) {
    final dateError = LastVisitError.of(next.date, calendarDay(_now()));
    final day = dateError == null ? parseDate(next.date) : null;
    final dueDates = [
      if (day != null)
        for (final item in _equipment)
          if (next.ticked.contains(item.id))
            if (_serviceTypes.where((type) => type.id == item.serviceTypeId).firstOrNull
                case final type?)
              nextDue(day, type.cycleMonths),
    ];
    final earliest = dueDates.isEmpty ? null : dueDates.reduce((a, b) => a.isBefore(b) ? a : b);
    emit(
      VisitFormState(
        isLoading: next.isLoading,
        isSaving: next.isSaving,
        isEditing: next.isEditing,
        equipment: next.equipment,
        ticked: next.ticked,
        date: next.date,
        price: next.price,
        note: next.note,
        dateError: dateError,
        isPriceInvalid: next.price.trim().isNotEmpty && parseMoney(next.price) == null,
        nextDueLabel: earliest == null ? null : formatDate(earliest),
      ),
    );
  }
}
