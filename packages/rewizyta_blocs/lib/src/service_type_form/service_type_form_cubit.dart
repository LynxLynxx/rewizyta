import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rewizyta_blocs/src/common/bloc_error_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/common/bloc_signal_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/service_type_form/service_type_form_state.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// Adds a service type to a trade, or edits one: name, cycle, default price
/// and archive. A new cycle moves the due dates ([CatalogService.saveServiceType]).
class ServiceTypeFormCubit(final CatalogService _catalogService)
    extends Cubit<ServiceTypeFormState>
    with
        BlocErrorEmitterMixin<ServiceTypeFormState>,
        BlocSignalEmitterMixin<ServiceTypeFormSignal, ServiceTypeFormState> {
  this : super(const ServiceTypeFormState());

  String? _id;
  String _tradeId = '';

  /// A new type under [tradeId], or [type] to edit. Synchronous: the sheet
  /// already holds everything it shows.
  void init({required String tradeId, ServiceTypeViewModel? type}) {
    _id = type?.id;
    _tradeId = tradeId;
    final price = type?.defaultPriceGrosze;
    emit(
      ServiceTypeFormState(
        isEditing: type != null,
        template: type?.template,
        // A default starts empty, its localized name as the hint.
        name: type?.name ?? '',
        cycle: '${type?.cycleMonths ?? 12}',
        price: price == null ? '' : formatMoney(price),
        isArchived: type?.isArchived ?? false,
      ),
    );
  }

  void update({String? name, String? cycle, String? price, bool? isArchived}) {
    emit(state.copyWith(name: name, cycle: cycle, price: price, isArchived: isArchived));
  }

  Future<void> save() async {
    if (!state.canSave) return;
    emit(state.copyWith(isSaving: true));
    try {
      await _catalogService.saveServiceType(
        id: _id,
        tradeId: _tradeId,
        name: state.name,
        cycleMonths: state.cycleMonths!,
        defaultPriceGrosze: parseMoney(state.price),
        isArchived: state.isArchived,
      );
      if (isClosed) return;
      emit(state.copyWith(isSaving: false));
      emitSignal(ServiceTypeFormSignal.saved);
    } on Exception catch (error) {
      if (isClosed) return;
      emit(state.copyWith(isSaving: false));
      emitError(LocalizedException.create(error));
    }
  }
}
