import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rewizyta_blocs/src/client_form/client_form_state.dart';
import 'package:rewizyta_blocs/src/common/bloc_error_emitter_mixin.dart';
import 'package:rewizyta_blocs/src/common/bloc_signal_emitter_mixin.dart';
import 'package:rewizyta_models/rewizyta_models.dart';
import 'package:rewizyta_services/rewizyta_services.dart';
import 'package:rewizyta_shared/rewizyta_shared.dart';
import 'package:rewizyta_view_models/rewizyta_view_models.dart';

/// Add (`init(null)`) or edit (`init(id)`) a client.
class ClientFormCubit(final ClientsService _clientsService)
    extends Cubit<ClientFormState>
    with
        BlocErrorEmitterMixin<ClientFormState>,
        BlocSignalEmitterMixin<ClientFormSaved, ClientFormState> {
  this : super(const ClientFormState());

  String? _id;

  Future<void> init(String? id) async {
    _id = id;
    if (id == null) return;
    emit(state.copyWith(isEditing: true, isLoading: true));
    try {
      final client = await _clientsService.getClient(id);
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
        ),
      );
    } on Exception catch (error) {
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

  Future<void> save() async {
    if (!state.canSave) return;
    emit(state.copyWith(isSaving: true));
    try {
      final client = await _clientsService.saveClient(
        id: _id,
        name: state.name,
        phone: state.phone,
        addressLine: state.addressLine,
        postalCode: state.postalCode,
        town: state.town,
        note: state.note,
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
}
